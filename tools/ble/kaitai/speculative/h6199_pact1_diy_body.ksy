meta:
  id: h6199_pact1_diy_body
  title: H6199 Pact 1 ordinary DIY upload body
  endian: le
  imports:
    - ../govee_shared
doc: |
  SPECULATIVE H6199 Pact 1/1, issue #293. The application constructs this
  body for A1 command 02 independently of A3 template and Studio bodies.
  The mix-pair byte length is present even for an ordinary single effect.
  Family, variation, palette and mixed-pair authorisation belongs to the
  exact revision catalogue, not this structural parser.
  Owner upload/ACK/activation exchanges remain unqualified.
seq:
  - id: diy_code
    type: u1
  - id: family
    type: u1
  - id: variation
    type: u1
  - id: speed
    type: u1
  - id: len_palette
    type: u1
  - id: palette
    type: palette_body
    size: len_palette
  - id: len_mix
    type: u1
  - id: mix
    type: mix_body
    size: len_mix
types:
  palette_body:
    seq:
      - id: colours
        type: govee_shared::rgb
        repeat: eos
  mix_body:
    seq:
      - id: pairs
        type: effect_pair
        repeat: eos
  effect_pair:
    seq:
      - id: family
        type: u1
      - id: variation
        type: u1
