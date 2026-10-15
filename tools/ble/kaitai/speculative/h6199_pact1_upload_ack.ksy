meta:
  id: h6199_pact1_upload_ack
  title: H6199 Pact 1 ordinary DIY transfer acknowledgement
doc: |
  SPECULATIVE H6199 Pact 1/1, issue #293. The application's A1 command 02
  controller matches protocol and opcode, then tests byte 2 for zero.
  This confirms an upload result only, not selector activation or content.
  Unknown tails and same-operation delayed-ACK ambiguity remain unresolved
  pending attributable owner exchanges.
seq:
  - id: protocol
    type: u1
    valid: 0xa1
  - id: opcode
    type: u1
    valid: 0x02
  - id: status
    type: u1
  - id: unknown_tail
    size: 16
  - id: checksum
    type: u1
instances:
  is_success:
    value: status == 0
