# PLEX canvas app scaffold

Data sources: `PLEX_ClaimAssignments`, `PLEX_Claims`, `PLEX_Users`. Flows: `PickNextClaim`, `TransitionStatus`.

## Screens
1. **scrHome**: queue counts per bucket, "Get next claim (GAP)" and "Get next claim (AUTH)" buttons.
2. **scrClaim**: claim detail, bucket badge, rework count, action buttons for the cards in `TransitionStatus`.
3. **scrExclude**: reason entry that calls `TransitionStatus` with `ExcludeClaim`.

## Power Fx

App.OnStart:
```
Set(gUser, User());
Set(gRoles, LookUp(PLEX_Users, UserEmail = User().Email));
```

Bucket counts on scrHome:
```
ClearCollect(colBuckets,
  AddColumns(GroupBy(Filter(PLEX_ClaimAssignments, Not(PL_Excluded) && IsBlank(UserId)), "PL_Bucket", "rows"),
    "Cnt", CountRows(rows)));
```

Get next claim:
```
Set(gPick, PickNextClaim.Run(gUser.Email, gUser.FullName, "gap"));
If(gPick.found, Navigate(scrClaim), Notify("No claims available", NotificationType.Information));
```

Bucket labels: 1 ALS/Purple Heart/Terminal/Homeless, 2 Backlog, 3 BWN, 4 Award return, 5 Atty fee, 6 All other.

The app is not generated as a `.msapp`. Build it in Power Apps Studio from this scaffold, or unpack a created app with `pac canvas unpack`.
