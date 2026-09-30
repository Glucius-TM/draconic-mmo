#include "Misc/AutomationTest.h"
#include "Modules/ModuleManager.h"

#if WITH_DEV_AUTOMATION_TESTS

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
	FDraconicClientModuleTest,
	"Draconic.Foundation.ClientModuleLoaded",
	EAutomationTestFlags::EditorContext | EAutomationTestFlags::SmokeFilter)

bool FDraconicClientModuleTest::RunTest(const FString& Parameters)
{
	return TestTrue(
		TEXT("The project descriptor loads the native client module"),
		FModuleManager::Get().IsModuleLoaded(TEXT("DraconicClient")));
}

#endif
