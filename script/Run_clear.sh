
# 小米应用商店文件夹判断
com_xiaomi_market() {
  if [[ "$(echo ${line} | grep "com.xiaomi.market")" != "" ]]; then
    if [[ "$(find ${line} -name "*.apk")" != "" ]]; then
      logd "[continue] --存在APK: ${line}"
      return 2
    fi
  fi
}

#使用while read是为了支持空格文件/文件夹
main_while_read() {
  cat ${Black_List} | grep -v '#' | grep -v '*' | while read line; do
    if [[ -d "${line}" ]]; then
      if [[ ! -z "$(cat ${White_List} | grep "${line}")" ]]; then
         logd "[continue] --白名单DIR: ${line}"
         continue
      fi
      com_xiaomi_market
      [[ $? == 2 ]] && continue
      rm -rf "${line}" && {
        let DIR++
        logd "[rm] --黑名单DIR: ${line}"
        echo "${DIR}" > ${tmp_date}/dir
      }
    fi
    if [[ -f "${line}" ]]; then
      if [[ ! -z "$(cat ${White_List} | grep "${line}")" ]]; then
        logd "[continue] --白名单FILE: ${line}"
        continue
      fi
      rm -rf "${line}" && {
        let FILE++
        logd "[rm] --黑名单FILE: ${line}"
        echo "${FILE}" > ${tmp_date}/file
      }
    fi
  done
}

#使用for是为了支持通配符*
main_for() {
  for i in `cat ${Black_List} | grep -v '#' | grep '*'`; do
    if [[ -d "${i}" ]]; then
      if [[ ! -z "$(cat ${White_List} | grep "${i}")" ]]; then
         logd "[continue] --白名单DIR: ${i}"
         continue
      fi
      rm -rf "${i}" && {
        let DIR++
        logd "[rm] --黑名单DIR: ${i}"
        echo "${DIR}" > ${tmp_date}/dir
      }
    fi
    if [[ -f "${i}" ]]; then
      if [[ ! -z "$(cat ${White_List} | grep "${i}")" ]]; then
        logd "[continue] --白名单FILE: ${i}"
        continue
      fi
      rm -rf "${i}" && {
        let FILE++ 
        logd "[rm] --黑名单FILE: ${i}"
        echo "${FILE}" > ${tmp_date}/file
      }
    fi
  done
}

find_black_main() {
  find_black="$(find /data/ -type f -name 'black')"
  if [[ ! -z ${find_black} ]]; then
    identifier="$(cat ${Black_List} | grep -w '#black标识符')"
    [[ -z ${identifier} ]] && echo "#black标识符" >> ${Black_List}
    for black_file_path in ${find_black}; do
      BLACK="${black_file_path%/black}"
      if [[ ! -z "$(cat ${White_List} | grep "${BLACK}")" ]]; then
        logd "[continue black] --白名单DIR: ${BLACK}"
        continue
      fi
      sed -i "/${identifier}/a${BLACK}" "${Black_List}"
    done
  fi
}

MODDIR=${0%/*}
[[ ! -d ${MODDIR}/tmp/DATE ]] && mkdir -p ${MODDIR}/tmp/DATE
. ${MODDIR}/clear_the_blacklist_functions.sh

if [[ "${Screen}" = "亮屏" ]]; then
  echo "亮屏"
  if [[ ! -f ${MODDIR}/tmp/Screen_on ]]; then
    touch ${MODDIR}/tmp/Screen_on
    logd "[状态]: [I]${Screen} 执行"
  fi
  tmp_date="${MODDIR}/tmp/DATE/$(date '+%Y%m%d')"
  if [[ ! -d "${tmp_date}" ]]; then
    rm -rf "${MODDIR}/tmp/DATE/*/" >/dev/null 2>&1
    mkdir -p ${tmp_date}
    echo "0" > ${tmp_date}/file
    echo "0" > ${tmp_date}/dir
    # 文件大小
    filesize="$(ls -l ${log} | awk '{print $5}')"
    # 3kb
    maxsize="$((1024*3))"
    [[ $filesize -gt $maxsize ]] && log_md_clear
  fi
  FILE="$(cat ${tmp_date}/file)"
  DIR="$(cat ${tmp_date}/dir)"

  find_black_main
  main_while_read
  main_for

  FILE="$(cat ${tmp_date}/file)"
  DIR="$(cat ${tmp_date}/dir)"
  sed -i "/^description=/c description=CROND: [ 今日已清除: ${FILE}个黑名单文件 | ${DIR}个黑名单文件夹 ] - Repo: https://github.com/Petit-Abba/black_and_white_list/" "${MODDIR%/script}/module.prop"
else
  echo "息屏"
  if [[ -f ${MODDIR}/tmp/Screen_on ]]; then
    rm -rf ${MODDIR}/tmp/Screen_on
    logd "[状态]: [W]${Screen} 不执行"
  fi
fi


