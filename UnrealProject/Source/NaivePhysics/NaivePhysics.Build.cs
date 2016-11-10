// Fill out your copyright notice in the Description page of Project Settings.

using System.IO;
using UnrealBuildTool;

public class NaivePhysics : ModuleRules
{
	public NaivePhysics(TargetInfo Target)
	{
		PublicDependencyModuleNames.AddRange(new string[] { "Core", "CoreUObject", "Engine", "InputCore", "ScriptGeneratorPlugin", "ScriptPlugin", "UETorch" });

		PrivateDependencyModuleNames.AddRange(new string[] {  });
	}
}
