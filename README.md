
#AI for Games III course project
A bot team for Heroes of Newerth. 

Course page: http://tkt-hon.github.io/midwars/
HoN Bot Repository for reference: https://github.com/honteam/Heroes-of-Newerth-Bots


# tkt-hon Midwars Tourney

    Alias "create_midwars_botmatch_1v1" "set teambotmanager_legion; set teambotmanager_hellbourne; BotDebugEnable; StartGame practice test mode:botmatch map:midwars teamsize:1 spectators:1 allowduplicate:true; g_botDifficulty 3; g_camDistanceMax 10000; g_camDistanceMaxSpectator 10000;"
    Alias "create_midwars_botmatch" "set teambotmanager_legion; set teambotmanager_hellbourne; BotDebugEnable; StartGame practice test mode:botmatch map:midwars teamsize:5 spectators:1 allowduplicate:true; g_botDifficulty 3; g_camDistanceMax 10000; g_camDistanceMaxSpectator 10000;"

## Teams

### Default bots by organizers

    Alias "team_default_legion" "set teambotmanager_legion default; AddBot 1 Default_Devourer; AddBot 1 Default_MonkeyKing; AddBot 1 Default_Nymphora; AddBot 1 Default_PuppetMaster; AddBot 1 Default_Valkyrie"

    Alias "team_default_hellbourne" "set teambotmanager_hellbourne default; AddBot 2 Default_Devourer; AddBot 2 Default_MonkeyKing; AddBot 2 Default_Nymphora; AddBot 2 Default_PuppetMaster; AddBot 2 Default_Valkyrie"

### xxx_CodeEveryDay420_xxx by Aleksi, Atte, Jesse
    Note! These commands have not been tested :)

    Alias "team_default_legion" "set teambotmanager_legion xxx_CodeEveryDay420_xxx; AddBot 1 xxx_CodeEveryDay420_xxx_Devourer; AddBot 1 xxx_CodeEveryDay420_xxx_MonkeyKing; AddBot 1 xxx_CodeEveryDay420_xxx_Nymphora; AddBot 1 xxx_CodeEveryDay420_xxx_PuppetMaster; AddBot 1 xxx_CodeEveryDay420_xxx_Valkyrie"

    Alias "team_default_hellbourne" "set teambotmanager_hellbourne xxx_CodeEveryDay420_xxx; AddBot 2 xxx_CodeEveryDay420_xxx_Devourer; AddBot 2 xxx_CodeEveryDay420_xxx_MonkeyKing; AddBot 2 xxx_CodeEveryDay420_xxx_Nymphora; AddBot 2 xxx_CodeEveryDay420_xxx_PuppetMaster; AddBot 2 xxx_CodeEveryDay420_xxx_Valkyrie"
