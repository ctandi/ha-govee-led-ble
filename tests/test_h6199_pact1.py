"""Source-driven Pact 1 candidate; synthetic radio results are not hardware qualification."""

from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from homeassistant.components.light import ColorMode

from custom_components.ha_govee_led_ble import coordinator as coordinator_module
from custom_components.ha_govee_led_ble.const import (
    MODEL_PROFILES,
    ReadDomain,
    SupportQuality,
    device_profile,
)
from custom_components.ha_govee_led_ble.control_arbiter import ControlIntent
from custom_components.ha_govee_led_ble.coordinator import GoveeBLECoordinator
from custom_components.ha_govee_led_ble.coordinator_status import ParsedMode
from custom_components.ha_govee_led_ble.effect_catalogue import MODEL_EFFECT_CATALOGUES
from custom_components.ha_govee_led_ble.effect_compiler import compile_application
from custom_components.ha_govee_led_ble.effect_contracts import device_effect_capabilities
from custom_components.ha_govee_led_ble.effect_deployments import PriorControlState
from custom_components.ha_govee_led_ble.effect_domain import LibraryItem, SingleEffect
from custom_components.ha_govee_led_ble.generated_protocol_adapter import (
    build_brightness,
    build_brightness_query,
    build_colour_mode_query,
    build_firmware_query,
    build_h6199_control_query,
    build_hardware_query,
    build_power_query,
    build_subordinate_query,
    build_white_balance,
)
from custom_components.ha_govee_led_ble.light import GoveeBLELight
from custom_components.ha_govee_led_ble.transport import ENCRYPTION_UUID
from custom_components.ha_govee_led_ble.video_applicability import video_control_states
from tests.test_govee_encryption import client as encryption_client
from tests.test_h6199_capabilities import lifecycle as pact_lifecycle  # noqa: F401
from tests.test_h6199_native_controls import frame

FIRMWARE, HARDWARE = "1.07.02", "1.00.01"


def advertise(c, pact):
    c._note_advertisement(SimpleNamespace(manufacturer_data={34818: bytes((0xEC, 0, pact, 1, 0))}))


def legacy_replies(replies, *, colours=None, brightness=136, camera=0):
    colours = [(255, 255, 255)] * 15 if colours is None else colours
    replies.update(
        {
            build_hardware_query("H6199"): frame("aa0703" + HARDWARE.encode().hex()),
            build_firmware_query("H6199"): frame("aa06" + FIRMWARE.encode().hex()),
            build_subordinate_query(0x20, "H6199"): frame("aa20" + b"1.00.01".hex()),
            build_subordinate_query(0x21, "H6199"): frame("aa21" + b"1.00.28".hex()),
            build_power_query("H6199"): frame("aa0101"),
            build_brightness_query("H6199"): frame(f"aa04{brightness:02x}"),
            build_colour_mode_query("H6199", selector=1): frame("aa050b00"),
            build_h6199_control_query("camera_status"): frame(f"aa32{camera:02x}"),
        }
    )
    for group in range(1, 5):
        records = colours[(group - 1) * 4 : group * 4]
        replies[frame(f"aaa2{group:02x}")] = frame(
            f"aaa2{group:02x}" + bytes(channel for colour in records for channel in colour).hex()
        )


@pytest.fixture
async def legacy_lifecycle(pact_lifecycle, monkeypatch):  # noqa: F811
    c, replies, clients, packets = pact_lifecycle
    advertise(c, 1)
    legacy_replies(replies)
    connect = coordinator_module.async_establish_ble_connection

    async def zero_marker_radio(*args, **kwargs):
        client = await connect(*args, **kwargs)
        marker = encryption_client(b"\0")
        client.services, client.read_gatt_char = marker.services, marker.read_gatt_char
        return client

    monkeypatch.setattr(coordinator_module, "async_establish_ble_connection", zero_marker_radio)
    yield c, replies, clients, packets


@pytest.mark.parametrize("model", ["H6199", "H6099", "H617A"])
def test_exact_model_and_positive_pact_choose_legacy_not_hardware_alone(model):
    unknown = device_profile(model, None, None, firmware=FIRMWARE, hardware=HARDWARE)
    modern = device_profile(model, 2, 1)
    legacy = device_profile(model, 1, 1, firmware=FIRMWARE, hardware=HARDWARE)
    if model != "H6199":
        assert unknown is modern is legacy is MODEL_PROFILES[model]
        return
    assert unknown.status_grammar == modern.status_grammar == "H6199"
    assert not unknown.supports_multi_layered_effects and not unknown.supports_video_inline_brightness
    assert legacy.support_quality is SupportQuality.EXPERIMENTAL
    assert legacy.status_grammar == legacy.effect_grammar == legacy.video_grammar == "H6199-Pact1"
    assert legacy.command_grammar == "H6199" and legacy.brightness_wire_range == (20, 254)
    assert legacy.outbound_transform(build_brightness(50, model)) == frame("330488")


def test_candidate_contract_has_complete_routes_and_no_newer_register_permissions():
    profile = device_profile("H6199", 1, 1, firmware=FIRMWARE, hardware=HARDWARE)
    assert profile.supports_rgb and profile.supports_color_temperature and profile.supports_scenes
    assert (profile.min_color_temp_kelvin, profile.max_color_temp_kelvin) == (2000, 9000)
    assert profile.segment_count == 15 and profile.segment_group_size == 4
    assert profile.supports_segment_writes and not profile.supports_segment_brightness
    assert (
        not profile.supports_white_balance
        and not profile.supports_relative_brightness
        and not profile.supports_blank_screen
    )
    assert not profile.can_read(ReadDomain.DISPLAY_SETTING) and not profile.can_read(ReadDomain.RELATIVE_BRIGHTNESS)
    assert profile.diy_requires_upload_ack and profile.scene_requires_upload_ack
    assert profile.dreamview_requires_upload_ack and profile.dreamview_max_sub_devices == 5
    assert len(profile.dreamview_operations) == 9 and len(profile.dreamview_reads) == 7
    metadata = MODEL_EFFECT_CATALOGUES["H6199"].to_dict(profile=profile)
    assert len(metadata["effects"]) == 8 and sum(len(f["variations"]) for f in metadata["effects"]) == 19
    assert "inline_brightness" in metadata["video_settings"]
    capabilities = device_effect_capabilities("entry", "H6199", "Legacy", 15, profile=profile).to_dict()
    assert capabilities["support_quality"] == "experimental"
    assert capabilities["custom_effects"]["single"] == capabilities["custom_effects"]["multi"] == "supported"
    assert "multi_layered" in capabilities["effect_categories"]


@pytest.mark.parametrize(
    "firmware,hardware,scenes",
    [(None, None, False), ("1.06.00", HARDWARE, False), ("1.06.01", HARDWARE, True), (FIRMWARE, HARDWARE, True)],
)
def test_source_main_identity_gates_service_scenes_not_basic_controls(firmware, hardware, scenes):
    profile = device_profile("H6199", 1, 1, firmware=firmware, hardware=hardware)
    assert profile.supports_scenes is scenes
    assert profile.supports_rgb and profile.supports_music_mode and profile.supports_custom_effects


async def test_real_legacy_setup_uses_zero_marker_register_brightness_and_rgb_only_pages(legacy_lifecycle):
    c, replies, clients, packets = legacy_lifecycle
    await c._async_update_data()
    assert c.available and c.is_on and c.color_mode is ParsedMode.COLOUR
    assert c.profile.supports_scenes and c.profile.support_quality is SupportQuality.EXPERIMENTAL
    assert (c.fw_version, c.hw_version) == (FIRMWARE, HARDWARE)
    assert c.brightness_pct == 50 and c.segment_colors == [(255, 255, 255)] * 15
    assert c.segment_state_source == "observed" and c.segment_brightness_source == "initial"
    assert not c._field_revisions.get("segment_brightness", 0)
    assert c._encryption.last_result == "plaintext" and c._encryption.marker_length == 1
    clients[0].read_gatt_char.assert_awaited_once_with(ENCRYPTION_UUID)
    assert all(frame(f"aaa2{group:02x}") in packets for group in range(1, 5))
    assert frame("aa0501") in packets and frame("aa05") not in packets
    assert not any(packet[:2] in (b"\xaa\xa5", b"\xaa\xa9", b"\xaa\xae", b"\xaa\x14") for packet in packets)
    light = GoveeBLELight(c)
    assert light.supported_color_modes == {ColorMode.RGB, ColorMode.COLOR_TEMP}
    assert "segment_brightness" not in light.extra_state_attributes
    state = c.capture_effect_control_state()
    assert PriorControlState.from_dict(state.to_dict()) == state
    assert state.segment_colors is not None and state.segment_brightness is None


async def test_real_legacy_brightness_and_partial_rgb_have_fresh_readback(legacy_lifecycle):
    c, replies, clients, packets = legacy_lifecycle
    await c._async_update_data()
    await c.send_command(build_brightness(50, c.model, profile=c.profile))
    assert packets[-1] == frame("330488")
    assert await c.refresh_state(expected_brightness=50)
    colours = [(255, 255, 255)] * 15
    colours[0] = colours[14] = (18, 52, 86)
    legacy_replies(replies, colours=colours)
    await c.async_paint_segments([([1, 15], (18, 52, 86))])
    assert frame("33050b12345600000140") in packets
    assert c.segment_colors == colours and c.segment_state_source == "observed"
    assert c.segment_brightness_source == "initial"
    assert not c._field_revisions.get("segment_brightness", 0)


@pytest.mark.parametrize("identity_returns", [True, False])
async def test_legacy_reconnect_requires_fresh_identity_without_requiring_camera(legacy_lifecycle, identity_returns):
    c, replies, clients, packets = legacy_lifecycle
    await c._async_update_data()
    assert c.profile.supports_scenes
    assert video_control_states(c.profile, c)["inline_brightness"].value == "supported"
    del replies[build_h6199_control_query("camera_status")]
    if not identity_returns:
        del replies[build_firmware_query("H6199")]
    await c._async_update_data()
    assert c.available and len(clients) == 2
    assert c.camera_status == "unknown"
    assert c.profile.supports_rgb and c.profile.supports_custom_effects
    assert c.profile.supports_scenes is identity_returns
    assert video_control_states(c.profile, c)["inline_brightness"].value == (
        "supported" if identity_returns else "evidence_gap"
    )


async def test_newer_register_is_rejected_before_state_or_write(hass, monkeypatch):
    c = GoveeBLECoordinator(hass, "11:22:33:44:55:66", "H6199", configuration_url=None)
    advertise(c, 1)
    client = MagicMock(is_connected=True, write_gatt_char=AsyncMock())
    c._client = client
    monkeypatch.setattr(c, "_ensure_connected", AsyncMock(return_value=client))
    before = c.capture_effect_control_state()
    with pytest.raises(ValueError):
        await c.async_write_effect_sequence(
            (build_white_balance(21, 5, c.model),), intent=ControlIntent.USER, state_values={"brightness_pct": 50}
        )
    assert c.capture_effect_control_state() == before and c.control_write_attempts == 0
    client.write_gatt_char.assert_not_awaited()


async def test_late_revision_keeps_library_and_rejects_prepared_modern_upload(hass, monkeypatch):
    c = GoveeBLECoordinator(hass, "11:22:33:44:55:66", "H6199", configuration_url=None)
    item = LibraryItem.new("Legacy recipe", SingleEffect(0, 0, 50, ((1, 2, 3),)))
    before = item.to_dict()
    advertise(c, 1)
    compiled = compile_application(item, c.model, profile=c.profile)
    assert compiled.upload_transport == "a1_02" and item.to_dict() == before
    c._note_advertisement(SimpleNamespace(manufacturer_data={}))
    assert c.profile.status_grammar == "H6199-Pact1"
    advertise(c, 2)
    from custom_components.ha_govee_led_ble.effect_compiler import validate_compiled_geometry

    with pytest.raises(ValueError, match="profile changed"):
        validate_compiled_geometry(compiled, c.profile)
    assert item.to_dict() == before
    assert c.profile.status_grammar == "H6199"


async def test_legacy_unknown_mode_and_music_flags_never_install_observations(hass):
    c = GoveeBLECoordinator(hass, "11:22:33:44:55:66", "H6199", configuration_url=None)
    advertise(c, 1)
    before = c.capture_effect_control_state()
    for payload in ("aa051304320001123456", "aa050c033202"):
        c._notify_callback(None, bytearray(frame(payload)))
    assert c.capture_effect_control_state() == before
    assert not c._field_revisions
    assert all(packet["outcome"] == "rejected" for packet in c.packet_log)


def test_inline_brightness_needs_fresh_main_and_subordinate_identity():
    profile = device_profile("H6199", 1, 1, firmware=FIRMWARE, hardware=HARDWARE)
    identity = SimpleNamespace(pact_type=1, pact_code=1, fw_version=FIRMWARE, hw_version=HARDWARE)
    assert video_control_states(profile, identity)["inline_brightness"].value == "evidence_gap"
    identity.subordinate_20_version, identity.subordinate_21_version = "1.00.01", "1.00.28"
    assert video_control_states(profile, identity)["inline_brightness"].value == "supported"
    assert video_control_states(profile, identity)["white_balance"].value == "unsupported"
