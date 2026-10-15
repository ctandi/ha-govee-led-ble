meta:
  id: h6199_pact1_upload_frame
  title: H6199 Pact 1 ordinary DIY transfer frame
doc: |
  SPECULATIVE H6199 Pact 1/1, issue #293. Ordinary DIY reaches the shared
  A1 command 02 multipart controller. Index zero carries the data-frame
  count, numbered data frames carry sixteen bytes and FF ends the transfer.
  Owner timing, retry and acknowledgement exchanges remain unqualified.
seq:
  - id: protocol
    type: u1
    valid: 0xa1
  - id: opcode
    type: u1
    valid: 0x02
  - id: index
    type: u1
  - id: body
    size: 16
    type:
      switch-on: index
      cases:
        0: start_body
  - id: checksum
    type: u1
instances:
  is_final:
    value: index == 0xff
types:
  start_body:
    seq:
      - id: num_data_frames
        type: u1
      - id: unknown_tail
        size-eos: true
