# Offline-first app, with our own sync server reachable from inside Iran

Every core feature works with no network. Data lives on the device first, with IDs that can be synced, and syncs to our own server when it can reach it. The server handles accounts, cross-device sync and later presence, and is run with docker compose. It must be hostable where it stays reachable from Iran's domestic network during international outages. We chose this over a hosted backend (Firebase, Supabase cloud) because those would break exactly when our users lose international connectivity.
