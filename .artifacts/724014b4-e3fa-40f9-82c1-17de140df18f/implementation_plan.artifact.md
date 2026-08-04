# Add Emergency SOS Button to Worker Side

Add the Emergency SOS floating action button to the Worker side of the app, specifically on the "Jobs" tab, to match the Customer side's safety features.

## Proposed Changes

### [Worker Feature]

#### [MODIFY] [worker_home_shell.dart](file:///home/nikolai/TOLY-MOLY-APP/lib/features/worker/worker_home_shell.dart)
- Import `showEmergencyBottomSheet` from `../safety/emergency_bottom_sheet.dart`.
- Update `floatingActionButton` logic in `WorkerHomeShell` to show the SOS button when the "Jobs" tab (index 1) is active.

## Verification Plan

### Manual Verification
1. Run the app in Worker mode.
2. Navigate to the "Jobs" tab (second tab).
3. Verify that the red "SOS" button is visible.
4. Tap the SOS button and verify that the Emergency Bottom Sheet opens.
5. Verify that the "Home" tab still shows the AI Assistant (AgentFab).
6. Verify that other tabs have no FAB.
