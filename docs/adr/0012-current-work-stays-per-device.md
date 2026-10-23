# The current Work is picked per device and never synced

Which Work is current, the one Tonight, Start and the home screen widget use, is a setting on each device (`currentWork` in the settings table). Sync carries the Works, their Positions, the journal and the Notes, but not that choice. A device that has no current Work after a sync, such as a new phone after its first pull, makes the most recently changed Work current (`WorkRepository.keepOneCurrent`, run by `SyncUseCase`). A device that already has one keeps it.

What to read tonight is picked on the phone in hand, often next to the book itself: a paper book on the phone, a podcast on the laptop. If the choice synced, picking on one device would quietly switch the other, and two devices picking in the same evening would fight over last-write-wins. Keeping it per device costs one tap the first time a Work is picked on a second device, and it needs no server or protocol change.

If users ask for "continue on the other device", the next step is for a device that starts a Session to make that Work current elsewhere, from the synced journal, rather than syncing the setting.
