import { expect, test } from "vitest";

import {
  cloneMusicProfileContent,
  cloneVideoProfileContent,
  MUSIC_STYLE_HELP,
  musicStyleCalm,
  musicStyleValue,
  videoCaptureAreaFullScreen,
  videoCaptureAreaValue,
} from "../../src/profile-model";
import { decodeEffectContent } from "../../src/validation";

test("profile clones isolate nested colour, parameter, and brightness state", () => {
  const music = {
    kind: "music_profile" as const,
    model: "H617A" as const,
    mode: "rhythm",
    sensitivity: 50,
    colour: [1, 2, 3] as [number, number, number],
    calm: null,
    parameters: { nested: { value: 1 } },
  };
  const video = {
    kind: "video_profile" as const,
    model: "H6199" as const,
    mode: "movie" as const,
    full_screen: true,
    saturation: 50,
    sound_effects: false,
    sound_effects_softness: 50,
    white_balance_position: 17,
    relative_brightness: {
      left: 100,
      top: 100,
      right: 100,
      bottom: 100,
    },
    blank_screen: false,
  };
  const musicClone = cloneMusicProfileContent(music);
  const videoClone = cloneVideoProfileContent(video);

  musicClone.colour![0] = 9;
  const nested = musicClone.parameters.nested;
  if (
    typeof nested !== "object" ||
    nested === null ||
    Array.isArray(nested)
  ) {
    throw new Error("Expected nested profile parameters.");
  }
  nested.value = 2;
  if (videoClone.relative_brightness === null) {
    throw new Error("Expected relative brightness.");
  }
  videoClone.relative_brightness.left = 20;

  expect(music.colour).toEqual([1, 2, 3]);
  expect(music.parameters).toEqual({ nested: { value: 1 } });
  expect(video.relative_brightness.left).toBe(100);
});

test("binary profile controls use stable select values", () => {
  expect(musicStyleValue(false)).toBe("dynamic");
  expect(musicStyleValue(true)).toBe("calm");
  expect(musicStyleCalm("dynamic")).toBe(false);
  expect(musicStyleCalm("calm")).toBe(true);
  expect(videoCaptureAreaValue(true)).toBe("full");
  expect(videoCaptureAreaValue(false)).toBe("part");
  expect(videoCaptureAreaFullScreen("full")).toBe(true);
  expect(videoCaptureAreaFullScreen("part")).toBe(false);
});

test("legacy inline video brightness survives decoding with its authoring bounds", () => {
  const content = {
    kind: "video_profile", model: "H6199", mode: "movie",
    full_screen: null, saturation: null, sound_effects: null, sound_effects_softness: null,
    white_balance_position: null, relative_brightness: null, blank_screen: null,
    inline_brightness: 50,
  };
  expect(decodeEffectContent(content)).toEqual(content);
  for (const value of [0, 101, true]) {
    expect(() => decodeEffectContent({...content, inline_brightness: value})).toThrow();
  }
});

test("music Style help distinguishes both options in project wording", () => {
  expect(MUSIC_STYLE_HELP.label).toBe("Style information");
  expect(MUSIC_STYLE_HELP.text).toContain("Dynamic");
  expect(MUSIC_STYLE_HELP.text).toContain("Calm");
  expect(MUSIC_STYLE_HELP.text).toContain("active response");
  expect(MUSIC_STYLE_HELP.text).toContain("restrained response");
});
