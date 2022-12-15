function anithr ($who, $msg) {
#used by several other functions, depends on variables set in Credentials.ps1
   return (Invoke-RestMethod -Method Post -Uri "$((get-variable "kong$who").value)$msg")
}

<# don't remember why I have this
function kongname ($id) {
	$uri = "https://api.kongregate.com/api/user_info.json?user_id=$($id)&friends=false"
	$result = Invoke-RestMethod -Method Post -Uri "$($uri)"
	return $result
}
#>

<# not currently working
function Do-Swole ($who, $level, $max=8) {
	$init = anithr -who $who -msg "init"
	$energy = $init.active_events.(900019).challenge_data.energy.current_value
	if ($energy -lt $max) {
		$max = $energy
	}
	for ($loop=0;$loop -lt $max;$loop++) {
		$attack = anithr -who $who -msg "startChallenge&challenge_id=1031&level=$level"
		$play = anithr -who $who -msg "playCard&battle_id=$($attack.battle_data.battle_id)&skip=True"
		$init = anithr -who $who -msg "init"
		"$($init.user_items.(210001).number) - $($init.active_events.(900019).challenge_data.energy.current_value)"
	}
}
#>

function Train-Swole ($who, $hero, $times=1) {
#depends on variables set in Hero-IDs.ps1
#example: Train-Swole -who me -hero "Hank" -times 2      --- will train Hank twice; if someone is currently training, it will wait until it's finished
	for ($loop=0;$loop -lt $times;$loop++) {
		$user = anithr -who $who -msg getUserAccount
		$swoleIndex = (($user.user_tasks.psobject.Properties.value | ? { $_.task_type -eq 2 }).task_index)
		$swoleTask = $user.user_tasks.$swoleIndex
		$ttw = $swoleTask.end_time-$user.time
		$heroId = $heroToId[$hero]
		if ($heroId -eq $null) {
			"Bad hero name, possible names are:"
			$idToHero.values
		} else {
			"Waiting $ttw seconds until training $hero ($heroId)"
			Start-Sleep $($ttw+5)
			$completeTraining=anithr -who $who -msg "completeHeroTraining&task_index=$($swoleIndex)"
			$startTraining=anithr -who $who -msg "startHeroTraining&hero_id=$($heroId)"
		}
	}
}

function Train-Swole-Multi ($who, $heroes) {
#depends on variables set in Hero-IDs.ps1
#example: Train-Swole-Multi -who me -heroes "Hank","Bob","Bobby","Hank"     --- will train Hank, then Bob, then Bobby, then Hank again; if someone is currently training, it will wait until it's finished
#example: Train-Swole-Multi -who me -heroes "Bobby","Bobby"    --- this is equivalent to Train-Swole -who me -hero "Bobby" -times 2
foreach ($hero in $heroes) {
		$user = anithr -who $who -msg getUserAccount
		$swoleIndex = (($user.user_tasks.psobject.Properties.value | ? { $_.task_type -eq 2 }).task_index)
		$swoleTask = $user.user_tasks.$swoleIndex
		$ttw = $swoleTask.end_time-$user.time
		$heroId = $heroToId[$hero]
		if ($heroId -eq $null) {
			"Bad hero name, possible names are:"
			$idToHero.values
		} else {
			"Waiting $ttw seconds until training $hero ($heroId)"
			Start-Sleep $($ttw+5)
			$completeTraining=anithr -who $who -msg "completeHeroTraining&task_index=$($swoleIndex)"
			$startTraining=anithr -who $who -msg "startHeroTraining&hero_id=$($heroId)"
		}
	}
}

function Check-Rumble ($who) {
    anithr -who $who -msg getGuildWarStatus
    if ($gw.time -lt $gw.guild_war_event_data.tracking_end_time) {
       "$($who):`t$($gw.guild_war_event_data.energy.current_value) rumble energy remaining."
    }
}

function Check-Research ($who) {
    $user = anithr -who $who -msg getUserAccount
    $user.user_tasks.psobject.Properties | % { "$($who):`t$(([math]::Round(($_.value.end_time - $user.time)/60/60)))h $(([math]::Round(($_.value.end_time - $user.time)/60)))m $($_.value.end_time - $user.time)s`t$($_.value.task_id_1) + $($_.value.task_id_2)`tSlot $($_.value.slot_index)" }
}

function Check-Siege ($who) {
    $members = (anithr -who $who -msg "updateGuild").faction.members
    $siegeStats = (anithr -who $who -msg "getRankings&ranking_index=0&ranking_id=event_guild_siege").rankings.data

    $myinfo = Join-Object -Left $members -Right $siegeStats -LeftJoinProperty name -RightJoinProperty name -LeftProperties name -RightProperties stat, matches_played
    for ($loop = 0; $loop -lt $myinfo.Count; $loop++) {
        if ($myinfo[$loop].matches_played -eq $null) {
            $myinfo.item($loop).matches_played = 0
            $myinfo.item($loop).stat = 0
        }
    }
    $myinfo
}

<# not sure if this works anymore
function Find-Guild ($who, $name) {
   return (anithr -who $who -msg "searchGuildName&name=$name")
}
#>

<# not tested after 2019
function Find-Token ($who, $hero, $max) {
   $count = 1
   $ht = anithr -who $who -msg "getHuntingTargets"
   while ($ht.hunting_targets.psobject.Properties.value.hero_xp_id -ne $heroToId.$hero) {
      if ($count -gt $max) { "Not found within $($max) skips"; break }
      $skip = anithr -who $who -msg "startPracticeBattle&target_user_id=$($ht.hunting_targets.psobject.Properties.value.user_id)"
      $skip2 = anithr -who $who -msg "playCard&battle_id=$($skip.battle_data.battle_id)&skip=True"
      $ht = anithr -who $who -msg "getHuntingTargets"
      $count++
   }
   "Found!"
}
#>

function Convert-Island ($island) {
	return (([int]($island -split "-")[0] * 3) - (3 - [int]($island -split "-")[1]) + 100)
}

function Play-Adventure ($who, $island = "26-1") {
  $mission_id = Convert-Island($island)
	$init = anithr -who $who -msg "startMission&mission_id=$($mission_id)"
	$init = anithr -who $who -msg "playCard&battle_id=$($init.battle_data.battle_id)&skip=True"
	$init.battle_data.rewards
}
