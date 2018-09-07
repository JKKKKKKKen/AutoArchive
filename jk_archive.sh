#!/bin/bash
# 打包脚本
# Mail:  271296246@qq.com
# Update: 2018.9.6

#name,version
function recordArchiveLog() {
#   打包Log路径
LogPath="${WorkPath}/archive.log"

#   上次打包时间
RecordTime=$(head -1 $LogPath)
#   获取git记录
Git_log=$(git log --pretty=format:"%h - %an, %ad : %s"  --since="${RecordTime}")

echo -e "\n\n----------------------------------------------------">>"${LogPath}"
echo -e "[$1] [$2] [$APP_BuildVersion] \n[$(date)]">>"${LogPath}"
echo -e '----------------------------------------------------'>>"${LogPath}"
#   更新Log记录时间
UpdateTime=$(date +%Y-%m-%dT%H:%M:%S | sed 's/-0/-/g')
sed -i "" "s/$RecordTime/$UpdateTime/g" "${LogPath}"

if [[ -z $Git_log ]];
then
echo "Git_log is empty."
else
echo "Git_log is not empty."
#   写入到日志
echo -e "${Git_log}" >> "${LogPath}"
fi

}


#-------------------------   变量定义  -------------------------

Targets_Name="ArchiveTest"

#   获取脚本文件存放路径
ShellPath=$(cd "$(dirname "$0")"; pwd)
readonly ShellPath

#  .xcodeproj所在路径
WorkPath="${ShellPath}"
readonly WorkPath

#   plist文件路径
PlistFile_Path="${WorkPath}/${Targets_Name}/Info.plist"
readonly PlistFile_Path

#   APP名
APP_DisplayName=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" $PlistFile_Path)
readonly APP_DisplayName

#   APP版本
APP_Version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${PlistFile_Path})
#   构建版本号
APP_BuildVersion=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${PlistFile_Path})

#IPA包文件夹名
IPA_Name=`date +%Y-%m-%d_%H-%M`
#   打包路径
IPA_Path="${WorkPath}/build_release_${IPA_Name}"
#   打包开始时间
Archive_Start_Time=`date +%s`
SLEEP_TIME=0.3


#-------------------------   变量定义  -------------------------

#-------------------------   代码执行  -------------------------

#echo -e "\033[36;1m 内容 \033[0m"
#  配置编译模式
echo -e "\033[36;1m 请选择 编译模式 (输入序号, 按回车即可) \033[0m"
echo -e "\033[36;1m 1. Debug \033[0m"
echo -e "\033[36;1m 2. Release \033[0m"
read parameter
sleep ${SLEEP_TIME}
Build_Configuration_Selectd="${parameter}"

# 判读用户是否有输入
if [[ "${Build_Configuration_Selectd}" == "1" ]]; then
Configuration="Debug"
elif [[ "${Build_Configuration_Selectd}" == "2" ]]; then
Configuration="Release"
else
echo -e "\033[31m \n您输入 BUILD_CONFIGURATION 参数无效!!!\n \033[0m"
exit 1
fi


#   配置是否上传蒲公英
echo -e "\033[36;1m 请选择 是否上传蒲公英 (输入序号, 按回车即可) \033[0m"
echo -e "\033[36;1m 1. 上传 \033[0m"
echo -e "\033[36;1m 2. 不上传 \033[0m"
read parameter
sleep ${__SLEEP_TIME}
UploadPGYER="${parameter}"

# 拷贝项目代码到工作目录
cd $ShellPath
TEMP_F="temp"
echo -e "\033[36;1m (0x04)-->配置工程文件路径... \033[0m"

Project_Name=$(ls | grep xcodeproj | awk -F.xcodeproj '{print $1}')
#创建IPA文件夹
mkdir -p $IPA_Path

if [[ -z $Project_Name ]]; then
echo -e "\033[31m ERROR-错误401：找不到需要编译的工程,编译APP中断. \033[0m"
exit 401
fi

echo ""

# 编译打包
#打包完的程序目录
App_Dir="${IPA_Path}/${Targets_Name}.app"
#dSYM的路径
DSYM_Dir="${IPA_Path}/${Targets_Name}.app.dSYM"

#编译工程
echo -e "\033[36;1m (0x08)-->开始编译，耗时操作,请稍等... \033[0m"
xcodebuild -configuration "${Configuration}" -workspace "${ShellPath}/${Project_Name}".xcworkspace -scheme "${Targets_Name}" -arch arm64 ONLY_ACTIVE_ARCH=NO TARGETED_DEVICE_FAMILY=1 DEPLOYMENT_LOCATION=YES CONFIGURATION_BUILD_DIR="${IPA_Path}" clean build

#查询编译APP是否成功
if [ ! -d "${App_Dir}" ]; then
echo ""
echo -e "\033[31m --> ERROR-错误501：找不到编译生成的APP, 编译APP失败. \033[0m"
exit 1
else
echo -e "\033[36;1m (0x08) 编译APP完成! √ \033[0m"
fi

echo ""
echo -e "\033[36;1m (0x09)-->开始打包请稍等... \033[0m"
echo ""

IPA_APP_DIR="${ShellPath}/${APP_DisplayName}_${APP_Version}_${IPA_Name}"
mkdir "${IPA_APP_DIR}"

#创建打包生成目录
IPA_BuildPath="${IPA_APP_DIR}/${APP_DisplayName}_v${APP_Version}_build${APP_BuildVersion}.ipa"
APP_PATH="${IPA_APP_DIR}/${APP_DisplayName}_${APP_Version}.app"
SYM_PATH="${APP_PATH}.dSYM"

cd "${IPA_APP_DIR}"
mkdir "Payload"
cp -r "${App_Dir}" "Payload"
zip -r "${IPA_BuildPath}" "Payload"

#查询打包是否成功
if [ ! -f "${IPA_BuildPath}" ]; then
echo -e "\033[36;1m ---------------------------------------------------- \033[0m"
echo -e "\033[31m --> ERROR-错误501：找不到签名生成的IPA包,打包APP失败. \033[0m"
exit 1
else
echo -e "\033[36;1m (0x09) 打包APP完成! √ \033[0m"
echo ""
fi

#拷贝过来.app.dSYM到输出目录
mv "${DSYM_Dir}" "${SYM_PATH}"

rm -rf "${IPA_Path}"
date_end='expr date + %s'

times='expr $date_end + $date_starts'

echo -e "\033[36;1m (0x0A)-->Nice Worker! -->打包成功!  GET √ \033[0m"
echo -e "\033[36;1m ---------------------------------------------------- \033[0m"
echo -e "\033[36;1m 本地安装包--->  ${IPA_APP_DIR} \033[0m"
echo -e "\033[36;1m 耗时: ${times} s \033[0m"
echo -e "\033[36;1m 完成时间: `date` \033[0m"
echo -e "\033[36;1m ---------------------------------------------------- \033[0m"

#   记录打包数据
recordArchiveLog ${APP_DisplayName} ${APP_Version}
open "${IPA_APP_DIR}"


if [[ "${UploadPGYER}" == "1" ]]; then
#   上传
#   蒲公英Key
PGYER_User_Key="修改成你的蒲公英KEY"
PGYER_API_Key="修改成你的蒲公英KEY"
#   上传蒲公英
curl -F "file=@${IPA_BuildPath}" \
-F "uKey=$PGYER_User_Key" \
-F "_api_key=$PGYER_API_Key" \
"http://www.pgyer.com/apiv1/app/upload"

echo -e "\033[36;1m ${IPA_BuildPath} 上传 ${APP_DisplayName}.ipa 包 到 pgyer 成功 \033[0m"
elif [[ "${UploadPGYER}" == "2" ]]; then
echo "------------------------ 不上传蒲公英 打包结束 ------------------------"
echo -e "\033[36;1m ${IPA_BuildPath} ------------------------ 不上传蒲公英 打包结束 ------------------------ \033[0m"
else
echo "\n您输入的参数无效!!!\n"
echo -e "\033[31m --> \n您输入的参数无效!!!\n \033[0m"
fi

exit 0
#-------------------------   代码执行  -------------------------
