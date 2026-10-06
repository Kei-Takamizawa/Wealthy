#!/usr/bin/env python3
"""Add a UI-test runner in a disposable project, retaining the existing Wealthy app identity."""
from pathlib import Path
import plistlib
import subprocess
import sys
repo = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
assert repo not in out.parents and not out.exists()
project = out / 'Wealthy.xcodeproj'; project.mkdir(parents=True)
data = plistlib.loads(subprocess.check_output(['plutil','-convert','xml1','-o','-',str(repo/'Wealthy/Wealthy.xcodeproj/project.pbxproj')]))
objects = data['objects']; app = '84BE02D52EFFDCA6000C29F9'; root = '84BE02CE2EFFDCA6000C29F9'
objects['84BE02D82EFFDCA6000C29F9']['path'] = str(repo/'Wealthy/Wealthy')
objects['84BE02D82EFFDCA6000C29F9']['sourceTree'] = '<absolute>'
objects['C10000000000000000000002']['relativePath'] = str(repo/'WealthyCore')
for item in objects.values():
 settings=item.get('buildSettings',{})
 if settings.get('PRODUCT_BUNDLE_IDENTIFIER') == 'com.harrison.Wealthy':
  settings['INFOPLIST_FILE']=str(repo/'Wealthy/Wealthy/Info.plist');settings['CODE_SIGN_ENTITLEMENTS']=str(repo/'Wealthy/Wealthy/Wealthy.entitlements')
ids={k:f'CA20000000000000000000{i:02X}' for i,k in enumerate(['target','product','group','sources','frameworks','resources','debug','release','configs','dependency','proxy'],1)}
objects[ids['product']]={'isa':'PBXFileReference','explicitFileType':'wrapper.cfbundle','includeInIndex':0,'path':'Cycle2aUITests.xctest','sourceTree':'BUILT_PRODUCTS_DIR'}
objects[ids['group']]={'isa':'PBXFileSystemSynchronizedRootGroup','path':str(repo/'Verification/Cycle2aUI'),'sourceTree':'<absolute>'}
for phase in ['sources','frameworks','resources']:objects[ids[phase]]={'isa':f'PBX{phase.capitalize()}BuildPhase','buildActionMask':2147483647,'files':[],'runOnlyForDeploymentPostprocessing':0}
for name in ['debug','release']:objects[ids[name]]={'isa':'XCBuildConfiguration','name':name.capitalize(),'buildSettings':{'CODE_SIGN_STYLE':'Automatic','DEVELOPMENT_TEAM':'8M8WLS24AG','GENERATE_INFOPLIST_FILE':'YES','IPHONEOS_DEPLOYMENT_TARGET':'26.0','PRODUCT_BUNDLE_IDENTIFIER':'com.harrison.Wealthy.Cycle2aUITests','PRODUCT_NAME':'$(TARGET_NAME)','SDKROOT':'iphoneos','SWIFT_VERSION':'5.0','SWIFT_DEFAULT_ACTOR_ISOLATION':'MainActor','TARGETED_DEVICE_FAMILY':'1','TEST_TARGET_NAME':'Wealthy'}}
objects[ids['configs']]={'isa':'XCConfigurationList','buildConfigurations':[ids['debug'],ids['release']],'defaultConfigurationIsVisible':0,'defaultConfigurationName':'Release'}
objects[ids['proxy']]={'isa':'PBXContainerItemProxy','containerPortal':root,'proxyType':1,'remoteGlobalIDString':app,'remoteInfo':'Wealthy'}
objects[ids['dependency']]={'isa':'PBXTargetDependency','target':app,'targetProxy':ids['proxy']}
objects[ids['target']]={'isa':'PBXNativeTarget','buildConfigurationList':ids['configs'],'buildPhases':[ids[k] for k in ['sources','frameworks','resources']],'buildRules':[],'dependencies':[ids['dependency']],'fileSystemSynchronizedGroups':[ids['group']],'name':'Cycle2aUITests','productName':'Cycle2aUITests','productReference':ids['product'],'productType':'com.apple.product-type.bundle.ui-testing'}
objects[objects[root]['mainGroup']]['children'].append(ids['group']);objects[objects[root]['productRefGroup']]['children'].append(ids['product']);objects[root]['targets'].append(ids['target'])
objects[root]['attributes']['TargetAttributes'][ids['target']]={'CreatedOnToolsVersion':'27.0','TestTargetID':app}
(project/'project.pbxproj').write_bytes(plistlib.dumps(data,sort_keys=False))
def ref(id,name,product):return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{id}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:Wealthy.xcodeproj"/>'
a=ref(app,'Wealthy','Wealthy.app');t=ref(ids['target'],'Cycle2aUITests','Cycle2aUITests.xctest')
scheme=project/'xcshareddata/xcschemes';scheme.mkdir(parents=True)
(scheme/'Wealthy.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?><Scheme version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{a}</BuildActionEntry><BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">{t}</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO" parallelizable="NO">{t}</TestableReference></Testables></TestAction><LaunchAction buildConfiguration="Debug"><BuildableProductRunnable runnableDebuggingMode="0">{a}</BuildableProductRunnable></LaunchAction></Scheme>''')
print(project)
