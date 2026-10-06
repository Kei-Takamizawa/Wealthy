#!/usr/bin/env python3
"""Create a disposable UI-test project with a separate app identity; never edit the shipping project."""
import argparse
from pathlib import Path
import plistlib
import json
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path, help='An empty temporary directory outside the repository')
parser.add_argument('--team', help='Signing team override; defaults to the shipping project team')
parser.add_argument('--receipt-images', type=Path, help='Private fixture directory; copied outside Git')
parser.add_argument('--receipt-truth', type=Path, help='Private frozen manual labels')
args = parser.parse_args()
if bool(args.receipt_images) != bool(args.receipt_truth):
    parser.error('Supply both private image and truth paths')
repo = Path(__file__).resolve().parents[1]
out = args.output.resolve()
if out == repo or repo in out.parents:
    parser.error('Use a temporary directory outside the repository')
project = out / 'Wealthy.xcodeproj'
project.mkdir(parents=True, exist_ok=False)
source = repo / 'Wealthy/Wealthy.xcodeproj/project.pbxproj'
data = plistlib.loads(subprocess.check_output(['plutil', '-convert', 'xml1', '-o', '-', str(source)]))
objects = data['objects']
objects['C10000000000000000000002']['relativePath'] = str(repo / 'WealthyCore')
team = args.team or next((item.get('buildSettings', {}).get('DEVELOPMENT_TEAM') for item in objects.values() if item.get('buildSettings', {}).get('PRODUCT_BUNDLE_IDENTIFIER') == 'com.harrison.Wealthy' and item.get('buildSettings', {}).get('DEVELOPMENT_TEAM')), '')
app_id = '84BE02D52EFFDCA6000C29F9'
root_id = '84BE02CE2EFFDCA6000C29F9'
main_group = objects[root_id]['mainGroup']
products = objects[root_id]['productRefGroup']
objects['84BE02D82EFFDCA6000C29F9']['path'] = str(repo / 'LegacyApp')
objects['84BE02D82EFFDCA6000C29F9']['sourceTree'] = '<absolute>'
for item in objects.values():
    settings = item.get('buildSettings', {})
    if settings.get('PRODUCT_BUNDLE_IDENTIFIER') == 'com.harrison.Wealthy':
        settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.harrison.Wealthy.DeviceTest'
        settings['SWIFT_VERSION'] = '5.0'
        settings['INFOPLIST_FILE'] = str(repo / 'LegacyApp/Info.plist')
        settings['CODE_SIGN_ENTITLEMENTS'] = str(repo / 'Wealthy/Wealthy/Wealthy.entitlements')
        settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Wealthy Test'

ids = {name: f'DE71000000000000000000{index:02X}' for index, name in enumerate(['target','product','group','sources','frameworks','resources','debug','release','configurations','dependency','proxy'], 1)}
objects[ids['product']] = {'isa':'PBXFileReference','explicitFileType':'wrapper.cfbundle','includeInIndex':0,'path':'WealthyDeviceUITests.xctest','sourceTree':'BUILT_PRODUCTS_DIR'}
objects[ids['group']] = {'isa':'PBXFileSystemSynchronizedRootGroup','path':str(repo / 'Verification/DeviceUI'),'sourceTree':'<absolute>'}
for phase in ['sources','frameworks','resources']:
    objects[ids[phase]] = {'isa':f'PBX{phase.capitalize()}BuildPhase','buildActionMask':2147483647,'files':[],'runOnlyForDeploymentPostprocessing':0}
for config in ['debug','release']:
    objects[ids[config]] = {'isa':'XCBuildConfiguration','name':config.capitalize(),'buildSettings':{
        'CODE_SIGN_STYLE':'Automatic','DEVELOPMENT_TEAM':team,'GENERATE_INFOPLIST_FILE':'YES',
        'IPHONEOS_DEPLOYMENT_TARGET':'26.0','PRODUCT_BUNDLE_IDENTIFIER':'com.harrison.Wealthy.DeviceTestUITests',
        'PRODUCT_NAME':'$(TARGET_NAME)','SDKROOT':'iphoneos','SWIFT_VERSION':'5.0',
        'SWIFT_DEFAULT_ACTOR_ISOLATION':'MainActor','TARGETED_DEVICE_FAMILY':'1,2','TEST_TARGET_NAME':'Wealthy'}}
objects[ids['configurations']] = {'isa':'XCConfigurationList','buildConfigurations':[ids['debug'],ids['release']],'defaultConfigurationIsVisible':0,'defaultConfigurationName':'Release'}
objects[ids['proxy']] = {'isa':'PBXContainerItemProxy','containerPortal':root_id,'proxyType':1,'remoteGlobalIDString':app_id,'remoteInfo':'Wealthy'}
objects[ids['dependency']] = {'isa':'PBXTargetDependency','target':app_id,'targetProxy':ids['proxy']}
objects[ids['target']] = {'isa':'PBXNativeTarget','buildConfigurationList':ids['configurations'],'buildPhases':[ids['sources'],ids['frameworks'],ids['resources']],
    'buildRules':[],'dependencies':[ids['dependency']],'fileSystemSynchronizedGroups':[ids['group']],
    'name':'WealthyDeviceUITests','productName':'WealthyDeviceUITests','productReference':ids['product'],'productType':'com.apple.product-type.bundle.ui-testing'}
objects[main_group]['children'].append(ids['group'])
objects[products]['children'].append(ids['product'])
objects[root_id]['targets'].append(ids['target'])
objects[root_id]['attributes']['TargetAttributes'][ids['target']] = {'CreatedOnToolsVersion':'27.0','TestTargetID':app_id}
core_ids = {name: f'DE72000000000000000000{index:02X}' for index, name in enumerate(['target','product','group','sources','frameworks','resources','debug','release','configurations','dependency','proxy','fixtures','fixtureBuild'], 1)}
objects[core_ids['product']] = {'isa':'PBXFileReference','explicitFileType':'wrapper.cfbundle','includeInIndex':0,'path':'WealthyDeviceCoreTests.xctest','sourceTree':'BUILT_PRODUCTS_DIR'}
objects[core_ids['group']] = {'isa':'PBXFileSystemSynchronizedRootGroup','path':str(repo / 'Verification/DeviceCore'),'sourceTree':'<absolute>'}
for phase in ['sources','frameworks','resources']:
    objects[core_ids[phase]] = {'isa':f'PBX{phase.capitalize()}BuildPhase','buildActionMask':2147483647,'files':[],'runOnlyForDeploymentPostprocessing':0}
for config in ['debug','release']:
    settings = dict(objects[ids[config]]['buildSettings'])
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.harrison.Wealthy.DeviceTestCoreTests'
    settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
    settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/Wealthy.app/Wealthy'
    objects[core_ids[config]] = {'isa':'XCBuildConfiguration','name':config.capitalize(),'buildSettings':settings}
objects[core_ids['configurations']] = {'isa':'XCConfigurationList','buildConfigurations':[core_ids['debug'],core_ids['release']],'defaultConfigurationIsVisible':0,'defaultConfigurationName':'Release'}
objects[core_ids['proxy']] = {'isa':'PBXContainerItemProxy','containerPortal':root_id,'proxyType':1,'remoteGlobalIDString':app_id,'remoteInfo':'Wealthy'}
objects[core_ids['dependency']] = {'isa':'PBXTargetDependency','target':app_id,'targetProxy':core_ids['proxy']}
objects[core_ids['target']] = {'isa':'PBXNativeTarget','buildConfigurationList':core_ids['configurations'],'buildPhases':[core_ids['sources'],core_ids['frameworks'],core_ids['resources']],
    'buildRules':[],'dependencies':[core_ids['dependency']],'fileSystemSynchronizedGroups':[core_ids['group']],
    'name':'WealthyDeviceCoreTests','productName':'WealthyDeviceCoreTests','productReference':core_ids['product'],'productType':'com.apple.product-type.bundle.unit-test'}
objects[main_group]['children'].append(core_ids['group'])
objects[products]['children'].append(core_ids['product'])
objects[root_id]['targets'].append(core_ids['target'])
objects[root_id]['attributes']['TargetAttributes'][core_ids['target']] = {'CreatedOnToolsVersion':'27.0','TestTargetID':app_id}
if args.receipt_images:
    fixtures = out / 'ReceiptFixtures'
    fixtures.mkdir()
    labels = json.loads(args.receipt_truth.read_text())
    manifest = []
    for index, label in enumerate(labels, 1):
        original = args.receipt_images / label['file']
        anonymous = f'R{index:02d}'
        extension = original.suffix.lstrip('.')
        shutil.copyfile(original, fixtures / f'{anonymous}.{extension}')
        manifest.append(dict(id=anonymous, extension=extension, totalJPY=label.get('totalJPY'), date=label.get('date'), category=label.get('category'), lines=label.get('lines',[])))
    (fixtures / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False))
    objects[core_ids['fixtures']] = {'isa':'PBXFileReference','lastKnownFileType':'folder','path':str(fixtures),'sourceTree':'<absolute>'}
    objects[core_ids['fixtureBuild']] = {'isa':'PBXBuildFile','fileRef':core_ids['fixtures']}
    objects[core_ids['resources']]['files'].append(core_ids['fixtureBuild'])
    objects[main_group]['children'].append(core_ids['fixtures'])
(project / 'project.pbxproj').write_bytes(plistlib.dumps(data, sort_keys=False))
schemes = project / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True)
app_ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_id}" BuildableName="Wealthy.app" BlueprintName="Wealthy" ReferencedContainer="container:Wealthy.xcodeproj"/>'
core_ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{core_ids["target"]}" BuildableName="WealthyDeviceCoreTests.xctest" BlueprintName="WealthyDeviceCoreTests" ReferencedContainer="container:Wealthy.xcodeproj"/>'
test_ref = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids["target"]}" BuildableName="WealthyDeviceUITests.xctest" BlueprintName="WealthyDeviceUITests" ReferencedContainer="container:Wealthy.xcodeproj"/>'
(schemes / 'Wealthy.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry>
<BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">{test_ref}</BuildActionEntry>
<BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">{core_ref}</BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO" parallelizable="NO">{test_ref}</TestableReference><TestableReference skipped="NO" parallelizable="NO">{core_ref}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print(project)
print('App ID: com.harrison.Wealthy.DeviceTest; existing Wealthy data stays in its original app container.')
