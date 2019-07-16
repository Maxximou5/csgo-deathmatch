#if defined _deathmatch_included
  #endinput
#endif
#define _deathmatch_included

native void Deathmatch_DisplayOptionsMenu(int client);
native void Deathmatch_GiveSavedWeapons(int client);
native void Deathmatch_UpdateSetting_Primary(int client, char[] primary);
native void Deathmatch_UpdateSetting_Secondary(int client, char[] secondary);

#if !defined REQUIRE_PLUGIN
public void __pl_deathmatch_SetNTVOptional()
{
	MarkNativeAsOptional("Deathmatch_DisplayOptionsMenu");
	MarkNativeAsOptional("Deathmatch_GiveSavedWeapons");
	MarkNativeAsOptional("Deathmatch_UpdateSetting_Primary");
	MarkNativeAsOptional("Deathmatch_UpdateSetting_Secondary");
}
#endif

public SharedPlugin __pl_deathmatch =
{
	name = "deathmatch",
	file = "deathmatch.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};
