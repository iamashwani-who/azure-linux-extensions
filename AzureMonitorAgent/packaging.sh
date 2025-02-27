#! /bin/bash
set -e
source agent.version

usage()
{
    local basename=`basename $0`
    echo "usage: ./$basename <path to mdsd-<version>.{.deb, .rpm}> [path for zip output]"
}

input_path=$1
output_path=$2
PACKAGE_NAME="azuremonitor$AGENT_VERSION.zip"
if [[ "$1" == "--help" ]]; then
    usage
    exit 0
elif [[ ! -d $input_path ]]; then
    echo "DEB/RPM files path '$input_path' not found"
    usage
    exit 1
fi

if [[ "$output_path" == "" ]]; then
    output_path="../"
fi

# Packaging starts here
cp -r ../Utils .
cp ../Common/WALinuxAgent-2.0.16/waagent .

cp -r  ../LAD-AMA-Common/metrics_ext_utils .
cp -r  ../LAD-AMA-Common/telegraf_utils .
cp -r  ../Diagnostic/services .

# cleanup packages, ext
rm -rf packages MetricsExtensionBin ext/future amaCoreAgentBin agentLauncherBin
mkdir -p packages MetricsExtensionBin ext/future amaCoreAgentBin agentLauncherBin

# copy shell bundle to packages/
cp $input_path/azuremonitoragent_$AGENT_VERSION* packages/
cp $input_path/MetricsExtension* MetricsExtensionBin/
cp $input_path/amacoreagent amaCoreAgentBin/
cp $input_path/agentlauncher agentLauncherBin/

# copy just the source of python-future
cp -r ext/python-future/src/* ext/future

# make the shim.sh file executable
chmod +x shim.sh

# sync the file copy
sync

if [[ -f $output_path/$PACKAGE_NAME ]]; then
    echo "Removing existing $PACKAGE_NAME ..."
    rm -f $output_path/$PACKAGE_NAME
fi

echo "Packaging extension $PACKAGE_NAME to $output_path"
excluded_files="agent.version packaging.sh apply_version.sh update_version.sh"
zip -r $output_path/$PACKAGE_NAME * -x $excluded_files "./test/*" "./extension-test/*" "./references" "./ext/python-future/*" "./ext/future/future/backports/test/*"

# cleanup newly added dir or files
rm -rf Utils/ waagent
