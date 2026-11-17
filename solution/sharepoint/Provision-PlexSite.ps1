#Requires -Modules PnP.PowerShell
<#
Provisions the PLEX SharePoint lists. Idempotent: existing lists/fields are skipped.
Usage: .\Provision-PlexSite.ps1 -SiteUrl https://dvagov.sharepoint.com/sites/PLEX
#>
param(
    [string]$SiteUrl = 'https://dvagov.sharepoint.com/sites/PLEX'
)

Connect-PnPOnline -Url $SiteUrl -Interactive

function Ensure-List($title) {
    if (-not (Get-PnPList -Identity $title -ErrorAction SilentlyContinue)) {
        New-PnPList -Title $title -Template GenericList -OnQuickLaunch | Out-Null
        Write-Host "Created list $title"
    }
}

function Ensure-Field($list, $name, $type, [string[]]$choices, [switch]$index) {
    if (Get-PnPField -List $list -Identity $name -ErrorAction SilentlyContinue) { return }
    $p = @{ List = $list; DisplayName = $name; InternalName = $name; Type = $type; AddToDefaultView = $true }
    if ($choices) { $p.Choices = $choices }
    Add-PnPField @p | Out-Null
    if ($index) { Set-PnPField -List $list -Identity $name -Values @{ Indexed = $true } }
}

# ---- PLEX_Claims (one row per claim; Title = Claim ID) -------------------------------
$l = 'PLEX_Claims'; Ensure-List $l
Ensure-Field $l DateOfClaim DateTime -index
Ensure-Field $l ClaimLevelStatus Text
Ensure-Field $l Contentions Number
Ensure-Field $l DaysPending Number -index
Ensure-Field $l EPCode Text -index
Ensure-Field $l EPClaimLabel Text
Ensure-Field $l LifecyclePhase Text
Ensure-Field $l WorkType Text
Ensure-Field $l SpecialMission Text
Ensure-Field $l SpecialIssues Note
Ensure-Field $l VeteranFlash Note
Ensure-Field $l RegionalOffice Text
Ensure-Field $l VeteranName Text
Ensure-Field $l TerminalDigit Text
Ensure-Field $l PowerOfAttorney Text

# ---- PLEX_ClaimAssignments (one row per assignment; Title = Assignment ID) -----------
$l = 'PLEX_ClaimAssignments'; Ensure-List $l
Ensure-Field $l ClaimId Text -index
Ensure-Field $l AssignedTo Text
Ensure-Field $l UserId Text -index
Ensure-Field $l Team Text
Ensure-Field $l WorkflowPosition Text
Ensure-Field $l DaysAssignedToRO Number -index
Ensure-Field $l DateOfClaim DateTime -index
Ensure-Field $l DaysPending Number
# PLEX fields (rulesv1.2 / assignmentRulesv1.0)
Ensure-Field $l PL_assignmentStatus Choice ('PendingAward','RVSRCorrection','PendingAuth','AwardCorrection','PendingConcur','ContinuedAtAuth','Closed') -index
Ensure-Field $l PL_currentStatusTime DateTime
Ensure-Field $l PL_GAPAssigned Text
Ensure-Field $l PL_AUTHAssigned Text
Ensure-Field $l PL_GAPerOfRecord Text -index
Ensure-Field $l PL_AuthOfRecord Text -index
Ensure-Field $l PL_GappedByTeam Text
Ensure-Field $l PL_AuthByTeam Text
Ensure-Field $l PL_BWN Boolean
Ensure-Field $l PL_ALS Boolean
Ensure-Field $l PL_Homeless Boolean
Ensure-Field $l PL_Backlog Boolean
Ensure-Field $l PL_Terminal Boolean
Ensure-Field $l PL_PurpleHeartOriginal Boolean
Ensure-Field $l PL_AttyFee Boolean
Ensure-Field $l PL_Excluded Boolean -index
Ensure-Field $l PL_ExcludedReason Text
Ensure-Field $l PL_reworkIndicated Boolean
Ensure-Field $l PL_reworkCount Number
Ensure-Field $l PL_Sensitive Choice ('0','6','7')
# Computed by the EnrichClaim flow: 1..6 per assignmentRulesv1.0 buckets
Ensure-Field $l PL_Bucket Number -index

# ---- PLEX_Users (roles) -------------------------------------------------------------
$l = 'PLEX_Users'; Ensure-List $l
Ensure-Field $l UserEmail Text -index
Ensure-Field $l Team Text
Ensure-Field $l CanGap Boolean
Ensure-Field $l CanAuth Boolean
Ensure-Field $l IsAttyFeeAuthorizer Boolean

# ---- PLEX_Config (tunable rule values) ----------------------------------------------
$l = 'PLEX_Config'; Ensure-List $l
Ensure-Field $l Value Text
$config = [ordered]@{
    BacklogDays          = '125'
    MaxPerRequestDefault = '1'
    MaxPerRequestBucket1 = ''
    MaxPerRequestBucket2 = ''
    MaxPerRequestBucket3 = ''
    MaxPerRequestBucket4 = ''
    MaxPerRequestBucket5 = ''
    MaxPerRequestBucket6 = ''
}
foreach ($k in $config.Keys) {
    if (-not (Get-PnPListItem -List $l -Query "<View><Query><Where><Eq><FieldRef Name='Title'/><Value Type='Text'>$k</Value></Eq></Where></Query></View>")) {
        Add-PnPListItem -List $l -Values @{ Title = $k; Value = $config[$k] } | Out-Null
    }
}

# ---- PLEX_TermLists (data-driven term lists) ----------------------------------------
$l = 'PLEX_TermLists'; Ensure-List $l
Ensure-Field $l ListName Text -index
$terms = @{
    als         = 'Amyotrophic Lateral Sclerosis','ALS'
    bwn         = 'Blue Water Navy','Blue Water Agent Orange','BWN','Nehmer'
    homeless    = 'Homeless'
    purpleHeart = 'Purple Heart'
    terminal    = 'Terminally Ill'
    attyFee     = 'Private Attorney - Fees Payable','Potential Attorney Fee'
}
foreach ($list in $terms.Keys) {
    foreach ($t in $terms[$list]) {
        if (-not (Get-PnPListItem -List $l -Query "<View><Query><Where><And><Eq><FieldRef Name='ListName'/><Value Type='Text'>$list</Value></Eq><Eq><FieldRef Name='Title'/><Value Type='Text'>$t</Value></Eq></And></Where></Query></View>")) {
            Add-PnPListItem -List $l -Values @{ Title = $t; ListName = $list } | Out-Null
        }
    }
}

# ---- PLEX_StatusHistory (appendHistory from state machine) --------------------------
$l = 'PLEX_StatusHistory'; Ensure-List $l
Ensure-Field $l ClaimId Text -index
Ensure-Field $l FromStatus Text
Ensure-Field $l ToStatus Text
Ensure-Field $l Card Text
Ensure-Field $l ChangedBy Text

Write-Host 'Done.'
