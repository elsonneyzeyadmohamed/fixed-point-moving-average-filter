# Synthesis comparison

This directory contains the supplied Synopsys Design Compiler reports for the direct-form baseline and refreshed filter, plus scripts to reproduce the flow.

| Metric | Direct form | Refreshed | Change |
|---|---:|---:|---:|
| Cell area (library units) | 17,721.101980 | 12,987.237921 | -26.71% |
| Estimated dynamic power | 323.0997 µW | 176.1216 µW | -45.49% |
| Estimated cell leakage | 12.6213 µW | 7.2788 µW | -42.33% |
| QoR critical path length | 7.77 | 0.66 | -91.51% |
| Logic levels | 20 | 3 | -85.00% |
| Clock-gating cells | 1 | 34 | +33 |
| Gated registers | 256/257 (99.61%) | 293/294 (99.66%) | Both about 99.6% |
| Violating paths | 0 | 0 | Both meet supplied 10 ns clock constraint |

The refreshed form replaces the full-window combinational sum with a running sum, circular buffer, and shadow sum. In the supplied synthesis runs this reduced mapped area and logic depth, while using more state and clock-gating elements.

**Power caveat:** The power reports warn that primary inputs and sequential outputs have unannotated activity (PWR-414/PWR-415). These low-effort, zero-delay propagated values are tool estimates, not workload-accurate or measured silicon power. No SAIF/VCD was supplied.

The reports use Design Compiler O-2018.06-SP1, the same named TSMC libraries, clock-gating style, and 10 ns clock. These are existing reports, not fresh runs. The `refreshed/` and `non_recursive/` folders contain six reports each (area, clock gating, constraints, power, QoR, timing) and their `syn.tcl` scripts. To rerun, install Design Compiler and the licensed TSMC `.db` libraries locally, then run `dc_shell -f synthesis/refreshed/syn.tcl` and `dc_shell -f synthesis/non_recursive/syn.tcl` from the repository root. The proprietary libraries are not included.
