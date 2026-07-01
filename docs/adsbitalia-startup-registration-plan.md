## Plan: ADSBItalia Startup Registration Sync

Implement a one-time startup registration workflow in s6 startup.d that runs after UUID persistence, exits cleanly when adsbitalia.it is not configured, computes a deterministic effective parameter set (with explicit fallback order), compares against persisted state, and only re-registers when state changes. This minimizes unnecessary API traffic while guaranteeing token rotation when feeder identity changes.

**Steps**
1. Phase 1 - Bootstrap point and execution model.
2. Add a one-time startup script named 52-adsbitalia-register under rootfs/etc/s6-overlay/startup.d so it executes after 50-store-uuid and before longrun services.
3. In this script, source /scripts/common and /scripts/interpret_ultrafeeder_config and initialize s6wrap logging consistent with existing scripts. Depends on step 2.
4. Set REGISTER_URL to https://adsbitalia.it/api/register-feeder and define constants for config directory/file paths: /var/globe_history/adsbitalia and /var/globe_history/adsbitalia/adsbitalia.conf. Parallel with step 3.
5. Phase 2 - Eligibility and prior state loading.
6. Parse ULTRAFEEDER_CONFIG for entries targeting adsbitalia.it in both adsb and mlat sections; if neither exists, log and exit 0 immediately (no side effects). Depends on step 3.
7. Ensure /var/globe_history/adsbitalia exists (mkdir -p).
8. If /var/globe_history/adsbitalia/adsbitalia.conf exists, load all previously persisted key/value pairs into an in-memory map for comparison and fallback sourcing. Depends on step 7.
9. Normalize input parsing so missing values resolve to empty strings rather than causing script termination; keep startup non-fatal behavior by design (all failures should continue container startup unless explicitly critical). Depends on step 8.
10. Phase 3 - Effective value resolution.
11. Resolve FEEDER_ID using exact precedence: previous FEEDER_ID from adsbitalia.conf; uuid= argument from adsb adsbitalia.it entry; uuid= argument from mlat adsbitalia.it entry; UUID environment variable; generated /proc/sys/kernel/random/uuid; if still empty, log error and exit 0 (skip registration).
12. Resolve FEEDER_TOKEN using precedence: previous FEEDER_TOKEN from adsbitalia.conf; generated token using the Adsb-Italia install.sh algorithm (referenced lines 148-154).
13. Resolve FEEDER_NAME using precedence: MLAT_USER environment variable, else FEEDER_ID.
14. Resolve PUBLIC_IP using curl to a public IP service with timeout/fail-safe behavior; if unavailable, keep empty and allow downstream comparison/registration decision.
15. Resolve HOSTNAME_LOCAL from container hostname (hostname command).
16. Resolve LOCAL_BEAST_PORT from ultrafeeder internal beast_reduce_plus_out setting.
17. Resolve FEED_HOST and FEED_PORT from adsbitalia.it adsb entry in ULTRAFEEDER_CONFIG.
18. Resolve MLAT_HOST and MLAT_PORT from adsbitalia.it mlat entry in ULTRAFEEDER_CONFIG.
19. Set MLAT_RETURN_PORT fixed to 33106.
20. Resolve LAT, LON, ALT from existing container location variables (LAT/READSB_LAT, LONG-or-LON/READSB_LON, ALT/READSB_ALT precedence agreed with current repo conventions).
21. Phase 4 - Change detection and token rotation rule.
22. Compare resolved current values against previously loaded values across all persisted keys.
23. Enforce special rule: if FEEDER_ID changed from previous value, regenerate FEEDER_TOKEN with Adsb-Italia algorithm regardless of previous token value.
24. Recompute change set after potential token regeneration.
25. If no values changed and config file exists, log no-change and exit 0.
26. If file missing or any value changed, continue to persistence + registration. Depends on steps 22-25.
27. Phase 5 - Persistence and remote registration.
28. Persist full resolved key/value set to /var/globe_history/adsbitalia/adsbitalia.conf using deterministic key ordering for stable diffs.
29. Construct JSON payload with exact field mapping requested.
30. POST to REGISTER_URL using curl -fsS with Content-Type: application/json; on failure log warning and continue startup.
31. Exit 0 in all non-critical paths so startup remains non-blocking.
32. Phase 6 - Documentation and operator transparency.
33. Add a short section to README.md or README-grafana.md describing adsbitalia registration behavior, persisted file location, and token rotation condition (only on FEEDER_ID change).
34. Document expected ULTRAFEEDER_CONFIG examples containing adsbitalia.it adsb/mlat entries and uuid override behavior.

**Relevant files**
- /Users/ramon/Documents/GitHub/docker-adsb-ultrafeeder/rootfs/etc/s6-overlay/startup.d/50-store-uuid - startup ordering reference; confirms UUID persistence timing.
- /Users/ramon/Documents/GitHub/docker-adsb-ultrafeeder/rootfs/etc/s6-overlay/scripts/aggregator-urls - one-time work then clean exit/stop pattern and s6 logging style.
- /Users/ramon/Documents/GitHub/docker-adsb-ultrafeeder/rootfs/etc/s6-overlay/scripts/adsbx-stats - UUID extraction/fallback pattern and startup-safe behavior.
- /Users/ramon/Documents/GitHub/docker-adsb-ultrafeeder/rootfs/etc/s6-overlay/scripts/mlat-client - config argument parsing patterns for mlat entries and location variable conventions.
- /Users/ramon/Documents/GitHub/docker-adsb-ultrafeeder/rootfs/etc/s6-overlay/startup.d/52-adsbitalia-register - new one-time startup script to implement.
- /Users/ramon/Documents/GitHub/docker-adsb-ultrafeeder/README.md - operator/admin documentation update for feature behavior.

**Verification**
1. Scenario test: ULTRAFEEDER_CONFIG without adsbitalia.it entries -> script exits 0, no adsbitalia.conf created, no registration attempt logged.
2. First-run test: with adsbitalia.it entries and no prior config -> directory/file created, values resolved, registration attempted once.
3. Idempotency test: restart container unchanged -> no-change detected, no new registration call.
4. FEEDER_ID-rotation test: change uuid source (or explicit uuid=) -> FEEDER_ID changes, FEEDER_TOKEN regenerated, registration retriggered.
5. Partial-change test: modify non-ID field (for example feed_port) -> token unchanged, registration retriggered.
6. Failure-path test: force REGISTER_URL failure (network block) -> warning logged, startup continues.
7. Parsing robustness test: adsb entry present but mlat absent, and vice versa -> values degrade gracefully, no crash.
8. Public IP failure test: curl timeout/unreachable -> behavior matches agreed policy (retain previous or blank), startup continues.

**Decisions**
- Included scope: one-time startup registration, state persistence, change detection, conditional remote update, non-fatal behavior.
- Excluded scope: recurring retry daemon, backoff scheduler, cryptographic signing beyond requested token algorithm.
- Decision: startup.d is preferred over a dedicated longrun service because this is explicitly one-time startup logic.
- Decision: script must always fail-open for container startup (exit 0 on registration problems) per requested behavior.

**Further Considerations**
1. Public IP source policy: Option A single provider with timeout, Option B multi-provider fallback chain, Option C retain prior value if all providers fail (recommended: B + C).
2. Location variable mapping policy: Option A accept LONG as lon alias, Option B normalize strictly to LON only (recommended: A for backward compatibility).
3. Config format policy: Option A shell key=value file, Option B JSON file; recommended A to match existing shell scripting style and easy sourcing.