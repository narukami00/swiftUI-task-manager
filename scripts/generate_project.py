"""Regenerate the checked-in native Xcode project using only Python's standard library."""
from pathlib import Path
import hashlib
ROOT = Path(__file__).resolve().parents[1]
def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
objects = []
def obj(name, body):
    objects.append(f'{uid(name)} = {{ {body} }};')
    return uid(name)
def refs(names):
    return ', '.join(uid(n) for n in names) + ','
sources = sorted(p.name for p in (ROOT / 'TaskManager').glob('*.swift'))
for name in sources:
    obj('file:'+name, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{name}"; sourceTree = "<group>";')
    obj('build:'+name, f'isa = PBXBuildFile; fileRef = {uid("file:"+name)};')
for name in ['FirebaseAuth', 'FirebaseFirestore', 'FirebaseCore']:
    obj('product:'+name, f'isa = XCSwiftPackageProductDependency; package = {uid("firebase")}; productName = {name};')
    obj('link:'+name, f'isa = PBXBuildFile; productRef = {uid("product:"+name)};')
obj('firebase', 'isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/firebase/firebase-ios-sdk.git"; requirement = { kind = exactVersion; version = 12.19.3; };')
obj('app', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = TaskManager.app; sourceTree = BUILT_PRODUCTS_DIR;')
obj('config', 'isa = PBXFileReference; lastKnownFileType = folder; path = FirebaseConfig; sourceTree = "<group>";')
obj('configbuild', f'isa = PBXBuildFile; fileRef = {uid("config")};')
obj('sourcegroup', f'isa = PBXGroup; children = ({refs(["file:"+s for s in sources])}); path = TaskManager; sourceTree = "<group>";')
obj('products', f'isa = PBXGroup; children = ({uid("app")},); name = Products; sourceTree = "<group>";')
obj('main', f'isa = PBXGroup; children = ({refs(["sourcegroup", "config", "products"])}); sourceTree = "<group>";')
obj('sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({refs(["build:"+s for s in sources])}); runOnlyForDeploymentPostprocessing = 0;')
obj('frameworks', f'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({refs(["link:"+s for s in ["FirebaseAuth", "FirebaseFirestore", "FirebaseCore"]])}); runOnlyForDeploymentPostprocessing = 0;')
obj('resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({uid("configbuild")},); runOnlyForDeploymentPostprocessing = 0;')
for mode in ['Debug', 'Release']:
    common = 'CLANG_ENABLE_MODULES = YES; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SWIFT_VERSION = 5.0;'
    if mode == 'Debug':
        common += ' SWIFT_OPTIMIZATION_LEVEL = "-Onone"; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; DEBUG_INFORMATION_FORMAT = dwarf;'
    else:
        common += ' SWIFT_COMPILATION_MODE = wholemodule; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'
    obj('project'+mode, f'isa = XCBuildConfiguration; buildSettings = {{ {common} }}; name = {mode};')
    target = 'PRODUCT_BUNDLE_IDENTIFIER = com.rafsan.TaskManager; PRODUCT_NAME = "$(TARGET_NAME)"; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = TaskManager; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES; TARGETED_DEVICE_FAMILY = "1,2"; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; MARKETING_VERSION = 1.0; ENABLE_PREVIEWS = YES; SWIFT_EMIT_LOC_STRINGS = YES;'
    obj('target'+mode, f'isa = XCBuildConfiguration; buildSettings = {{ {target} }}; name = {mode};')
for scope in ['project','target']:
    obj(scope+'configs', f'isa = XCConfigurationList; buildConfigurations = ({refs([scope+"Debug",scope+"Release"])}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
obj('target', f'isa = PBXNativeTarget; buildConfigurationList = {uid("targetconfigs")}; buildPhases = ({refs(["sources","frameworks","resources"])}); buildRules = (); dependencies = (); name = TaskManager; packageProductDependencies = ({refs(["product:"+s for s in ["FirebaseAuth","FirebaseFirestore","FirebaseCore"]])}); productName = TaskManager; productReference = {uid("app")}; productType = "com.apple.product-type.application";')
obj('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1640; }}; buildConfigurationList = {uid("projectconfigs")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {uid("main")}; productRefGroup = {uid("products")}; projectDirPath = ""; projectRoot = ""; packageReferences = ({uid("firebase")},); targets = ({uid("target")},);')
project = ROOT / 'TaskManager.xcodeproj'
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+f'\n}}; rootObject = {uid("project")}; }}\n', encoding='utf-8')
scheme_dir = project / 'xcshareddata' / 'xcschemes'
scheme_dir.mkdir(parents=True, exist_ok=True)
ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target")}" BuildableName="TaskManager.app" BlueprintName="TaskManager" ReferencedContainer="container:TaskManager.xcodeproj"/>'
(scheme_dir / 'TaskManager.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1640" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''', encoding='utf-8')
print(f'Generated Xcode project with {len(sources)} Swift files.')
