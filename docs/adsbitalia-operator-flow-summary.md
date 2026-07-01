## Technical/Flow Architecture Summary for ADSBItalia Operator

This startup registration flow is designed as a deterministic state synchronization process with fail-open container behavior.

1. Trigger and timing
- Executes once on each container start, after UUID setup and before regular feeders are launched.

2. Eligibility gate
- The process activates only when ULTRAFEEDER_CONFIG includes adsbitalia.it in either an adsb entry or an mlat entry.
- If not present, the process exits immediately without contacting the API.

3. Persistent state model
- State directory: /var/globe_history/adsbitalia
- State file: /var/globe_history/adsbitalia/adsbitalia.conf
- The file stores last-sent effective values used for comparison and fallback.

4. Deterministic value resolution
- FEEDER_ID resolves via strict precedence (previous -> adsb uuid override -> mlat uuid override -> UUID env -> generated UUID).
- FEEDER_TOKEN resolves from previous value unless FEEDER_ID changes, in which case a new token is generated with the Adsb-Italia install algorithm.
- Network/feed/mlat/location fields are derived from runtime env plus ULTRAFEEDER_CONFIG parsing.

5. Change detection and update policy
- If this is not first run and no effective values changed, no registration request is sent.
- If first run or any value changed, local state is rewritten and one registration request is sent.

6. Registration API behavior
- Method: HTTP POST JSON to https://adsbitalia.it/api/register-feeder
- Payload includes feeder identity, token, operator/user label, host/IP, beast ports, feed endpoint, mlat endpoint, and location.
- feed_mode is fixed to push; mlat_return_port fixed to 33106.

7. Reliability and operational impact
- Registration failures are logged but never block container startup.
- This creates eventual consistency on next restart/change while protecting feeder availability.

8. Security/identity implications
- FEEDER_TOKEN remains stable across restarts unless FEEDER_ID changes.
- FEEDER_ID changes intentionally force token rotation to avoid stale identity-token pairings.

9. Expected operator-side validation checklist
- Confirm API accepts idempotent updates for unchanged or repeated payloads.
- Confirm token regeneration semantics when feeder_id changes.
- Confirm empty/unknown optional fields handling (for example temporary public_ip lookup failure).
- Confirm rate expectations: one call on first run, then only on effective configuration change.