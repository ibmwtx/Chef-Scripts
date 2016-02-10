#!/bin/ksh

FILE_REV=20151008

function InitializeEnv
{
	if [ -z "${VRMFNUM}" ]
	then
		VRMFNUM=9000
	fi
	VRNUM=`echo ${VRMFNUM} | awk '{ print substr ($1, 1, 2) }'`

	if [ "${VRMFNUM}" -lt "8100" ]
	then
		INSTCMD=DSTXINST
	else
		INSTCMD=DTXINST
	fi
 
	FINAL_STATUS=PASSED
	FINAL_RUN_STATUS=NOT_RUN


	ID=`id | cut -f2 -d'(' | cut -f1 -d')'`
	HOSTNAME=`hostname | sed -e 's,\..*$,,g'`
	HOST_TYPE=`uname`
	MACHINE_TYPE=`uname -m`
	PLATFORM=unknown
	PLATEXT=

	if [ "${HOST_TYPE}" = "AIX" ]
	then
		PLATFORM=aix
		slibclean
	elif [ "${HOST_TYPE}" = "HP-UX" ]
	then
		PLATFORM=hp
		if [ "${MACHINE_TYPE}" = "ia64" ]
		then
			PLATFORM=itanium
		fi
	elif [ "${HOST_TYPE}" = "Linux" ]
	then
		PLATFORM=linux
		PLATEXT=lnx
		if [ "${MACHINE_TYPE}" = "s390x" ]
		then
			PLATFORM=zlinux
			PLATEXT=znx
		elif [ "${MACHINE_TYPE}" = "ppc64" ]
		then
			PLATFORM=plinux
		    PLATEXT=mmc
		fi
	elif [ "${HOST_TYPE}" = "SunOS" ]
	then
		PLATFORM=sun
	fi


	if [ -z "${PLATEXT}" ]
	then
		if [ "${PLATFORM}" = "unknown" ]
		then
			PLATEXT=mmc
		else
			PLATEXT=${PLATFORM}
		fi
	fi

	TARSUFFIX=${VRMFNUM}_${PLATFORM}
	if [ "${VRMFNUM}" -ge "8400" -a ! -z "${BITTYPE}" ]
	then
		TARSUFFIX=${TARSUFFIX}_${BITTYPE}
	fi


	if [ -z "${BVTDIR}" ]
	then
		if [ "${ID}" = "bocaqa" ]
		then
			BVTDIR=/${HOSTNAME}home/qalocal/bvt${VRMFNUM}_64
		else
			BVTDIR=${HOME}/bvt${VRMFNUM}_64
		fi
	fi

	if [ -z "${BVTTESTDIR}" ]
	then
		if [ "${ID}" = "bocaqa" ]
		then
			BVTTESTDIR=/${HOSTNAME}home/qalocal/bvttest${VRNUM}
		else
			BVTTESTDIR=${HOME}/bvttests
		fi
	fi

	if [ -z "${TARBALLDIR}" ]
	then
		TARBALLDIR=${BVTDIR}/installs
	fi

	if [ -z "${INSTALL_PROMPTS}" ]
	then
		INSTALL_PROMPTS=${BVTDIR}/install_prompts
	fi

	if [ -z "${INSTALL_PROMPTS_DK}" ]
	then
		INSTALL_PROMPTS_DK=${INSTALL_PROMPTS}_dk
	fi


	if [ -z "${TXINSTALLS_CORE}" ]
	then
		INSTALLS_TOAPPLY_CORE="wsdtxcs wsdtxl wsdtxla wsdtxls wsdtxsac wsdtxsnmp"
	elif [ "${TXINSTALLS_CORE}" = "none" ]
	then
		INSTALLS_TOAPPLY_CORE=
	else
		INSTALLS_TOAPPLY_CORE=${TXINSTALLS_CORE}
	fi

	if [ -z "${TXINSTALLS_DK}" ]
	then
		INSTALLS_TOAPPLY_DK="wsdtxapi wsdtxsac wsdtxsnmp"
	elif [ "${TXINSTALLS_DK}" = "none" ]
	then
		INSTALLS_TOAPPLY_DK=
	else
		INSTALLS_TOAPPLY_DK=${TXINSTALLS_DK}
	fi

	if [ -z "${TXINSTALLS_INTERIMFIX}" ]
	then
		INSTALLS_TOAPPLY_INTERIMFIX="01 02"
	elif [ "${TXINSTALLS_INTERIMFIX}" = "none" ]
	then
		INSTALLS_TOAPPLY_INTERIMFIX=
	else
		INSTALLS_TOAPPLY_INTERIMFIX=${TXINSTALLS_INTERIMFIX}
	fi


	if [ "${PLATFORM}" = "zlinux" -a "${VRMFNUM}" = "8200" -a ! -z "${BVTDIR}" ]
	then
		export PATH=${BVTDIR}:${PATH}
	fi

	echo
	DumpSettings
}



function ask_yn
{
	DEBUG_PROMPT=
	if [ ! -z "$DEBUG_PROMPT" ]
	then
		echo
		read yn?"DEBUG: Continue (Hit Ctrl-C to stop)? "
		echo
	fi
}



function MakeDirectory
{
	MD_DIRECTORY=$1
	if [ ! -z "${MD_DIRECTORY}" -a ! -d "${MD_DIRECTORY}" ]
	then
		echo Creating directory ${MD_DIRECTORY}...
		if [ -a ${MD_DIRECTORY} ]
		then
			rm -f ${MD_DIRECTORY}
		fi
		mkdir -p ${MD_DIRECTORY}
	fi
}



function DumpSettings
{
	echo "=== ${PROGNAME}: `date`: Start: VRMFNUM=${VRMFNUM}  RUN_TESTS_ONLY=\"${RUN_TESTS_ONLY}\" (!Done:)"
	echo "===     BVTDIR=${BVTDIR}"
	echo "===     BVTTESTDIR=${BVTTESTDIR}"
	echo "===     TARBALLDIR=${TARBALLDIR}"
	echo "===     TARSUFFIX=${TARSUFFIX}  HOSTNAME=${HOSTNAME}  PLATFORM=${PLATFORM}"
	echo "===     INSTALL_PROMPTS=${INSTALL_PROMPTS}"
	echo "===     INSTALL_PROMPTS_DK=${INSTALL_PROMPTS_DK}"
	echo "=== User-specified install variables:"
	echo "===     TXINSTALLS_CORE=\"${TXINSTALLS_CORE}\""
	echo "===     TXINSTALLS_DK=\"${TXINSTALLS_DK}\""
	echo "===     TXINSTALLS_INTERIMFIX=\"${TXINSTALLS_INTERIMFIX}\""
	echo "===     TXINSTALLS_DPFILES=\"${TXINSTALLS_DPFILES}\""
	echo "=== User-specified variables impacting the response files:"
	echo "===     TXINSTALLDIR=\"${TXINSTALLDIR}\""
	echo "===     TXINSTALLDIR_DK=\"${TXINSTALLDIR_DK}\""
	echo "===     PRODSELECT=\"${PRODSELECT}\""
	echo "===     TXTMPDIR=\"${TXTMPDIR}\""
	echo "===     TXOWNUSER=\"${TXOWNUSER}\""
	echo "===     TXOWNGROUP=\"${TXOWNGROUP}\""
	echo "===     TXBROWSER=\"${TXBROWSER}\""
	echo "=== Values resulting from user-specified install variables:"
	echo "===     INSTALLS_TOAPPLY_CORE=\"${INSTALLS_TOAPPLY_CORE}\""
	echo "===     INSTALLS_TOAPPLY_DK=\"${INSTALLS_TOAPPLY_DK}\""
	echo "===     INSTALLS_TOAPPLY_INTERIMFIX=\"${INSTALLS_TOAPPLY_INTERIMFIX}\""
	echo "=== Current directory: ${PWD}"
	if [ ! -z "$LOGFILE" ]
	then
		echo "===     LOGFILE=\"${LOGFILE}\""
	fi
	if [ ! -z "$DEBUG_PROMPT" ]
	then
		echo "===     DEBUG_PROMPT defined: Will cause script to pause"
	fi
	if [ ! -z "$DEBUG_FILELIST" ]
	then
		echo "===     DEBUG_FILELIST defined: Will generate filelists after each install"
	fi

	ask_yn
}



function GenerateInstallPromptFiles
{
	CFIP_PROMPTFILE=$1
	CFIP_USE_DK=$2

	if [ ! -z "${CFIP_PROMPTFILE}" ]
	then
		echo "\n=== ${PROGNAME}: Generating ${CFIP_PROMPTFILE}:"
		rm -f ${CFIP_PROMPTFILE}

		if [ "${CFIP_USE_DK}" = "1" ]
		then
			echo "# `date`: Auto-generated for VRMFNUM=${VRMFNUM} - DK version" > ${CFIP_PROMPTFILE}
			if [ ! -z "${TXINSTALLDIR_DK}" ]
			then
				CFIP_INSTALLDIR=${TXINSTALLDIR_DK}
			else
				CFIP_INSTALLDIR=${BVTDIR}/wtx_${VRMFNUM}_dk
			fi
		else
			echo "# `date`: Auto-generated for VRMFNUM=${VRMFNUM}" > ${CFIP_PROMPTFILE}
			if [ ! -z "${TXINSTALLDIR}" ]
			then
				CFIP_INSTALLDIR=${TXINSTALLDIR}
			else
				CFIP_INSTALLDIR=${BVTDIR}/wtx_${VRMFNUM}
			fi
		fi

		if [ ! -z "${PRODSELECT}" ]
		then
			echo "PRODSELECT:${PRODSELECT}" >> ${CFIP_PROMPTFILE}
		else
			echo "PRODSELECT:all" >> ${CFIP_PROMPTFILE}
		fi

		echo "TXINSTALLDIR:${CFIP_INSTALLDIR}" >> ${CFIP_PROMPTFILE}

		if [ ! -z "${TXTMPDIR}" ]
		then
			CFIP_TMPDIR=${TXTMPDIR}
		else
			CFIP_TMPDIR=${BVTDIR}/tmp
		fi
		echo "TXTMPDIR:${CFIP_TMPDIR}" >> ${CFIP_PROMPTFILE}
		
		if [ ! -z "${TXOWNUSER}" ]
		then
			echo "TXOWNUSER:${TXOWNUSER}" >> ${CFIP_PROMPTFILE}
		else
			echo "TXOWNUSER:user" >> ${CFIP_PROMPTFILE}
		fi

		if [ ! -z "${TXOWNGROUP}" ]
		then
			echo "TXOWNGROUP:${TXOWNGROUP}" >> ${CFIP_PROMPTFILE}
		else
			echo "TXOWNGROUP:group" >> ${CFIP_PROMPTFILE}
		fi

		if [ ! -z "${TXBROWSER}" ]
		then
			echo "TXBROWSER:${TXBROWSER}" >> ${CFIP_PROMPTFILE}
		else
			echo "TXBROWSER:/usr/netscape" >> ${CFIP_PROMPTFILE}
		fi

		echo
		cat ${CFIP_PROMPTFILE} | sed -e 's,^,    ,'

		MakeDirectory ${CFIP_TMPDIR}
	fi
	ask_yn
}



function SetVarFromInstallPromptsFile
{
	SVFIPF_FUNCNAME=${FUNCNAME}
	FUNCNAME=SetVarFromInstallPromptsFile

	if [ ! -z "$1" -a ! -z "$2" ]
	then
		TMPSHELLFILE=./tmp_$0
		rm -f ${TMPSHELLFILE}

		echo $1=`grep $1 $2 | sed -e 's/^.*://'` > ${TMPSHELLFILE}
		. ${TMPSHELLFILE}
		# echo "=== ${FUNCNAME}: Using $2: `cat ${TMPSHELLFILE}`"
		# echo "=== ${FUNCNAME}: Using $2: `cat ${TMPSHELLFILE}`" >> $LOGFILE

		rm -f ${TMPSHELLFILE}
	fi

	FUNCNAME=${SVFIPF_FUNCNAME}
}



function RunInstallFromTarball 
{
	RIFTB_FUNCNAME=${FUNCNAME}
	FUNCNAME=RunInstallFromTarball
	STATUS=PASSED

	if [ ! -z "$1" -a ! -z "$2" ]
	then
		COMPONENT=$1
		PROMPTS=$2

		echo "\n=== ${FUNCNAME}: `date`: Start: COMPONENT=${COMPONENT} PROMPTS=${PROMPTS} PWD=$PWD"
		echo "\n=== ${FUNCNAME}: `date`: Start: COMPONENT=${COMPONENT} PROMPTS=${PROMPTS} PWD=$PWD" >> ${LOGFILE}

		ORIGDIR=$PWD
		EXTRACTDIR=${BVTDIR}/installs/${COMPONENT}
		INSTALLLOG=install_log
		if [ "${PROMPTS}" = "${INSTALL_PROMPTS_DK}" ]
		then
			INSTALLLOG=${INSTALLLOG}.dk
		fi
		INSTALLLOG=${INSTALLLOG}.${COMPONENT}
		INSTALLCMD="${EXTRACTDIR}/${INSTCMD} -s ${PROMPTS} -l ${BVTDIR}/${INSTALLLOG}"

		ask_yn

		if [ -f ${TARBALLDIR}/${COMPONENT}_${TARSUFFIX}.tar ]
		then
			echo "=== ${FUNCNAME}: `date`: Untarring image..."
			echo "=== ${FUNCNAME}: `date`: Untarring image..." >> ${LOGFILE}
			rm -rf ${EXTRACTDIR} >> ${LOGFILE} 2>&1
			mkdir -p ${EXTRACTDIR} >> ${LOGFILE} 2>&1
			cd ${EXTRACTDIR} >> ${LOGFILE} 2>&1
			tar -xvf ../${COMPONENT}_${TARSUFFIX}.tar >> ${LOGFILE} 2>&1


			if [ "${COMPONENT}" = "wsdtxif01" -a "${PROMPTS}" = "${INSTALL_PROMPTS_DK}" -a -f "../${INSTCMD}.${COMPONENT}" ]
			then
				LOGSTR="=== ${FUNCNAME}: STATUS=WARNING: Using patched ${INSTCMD} for IF01..."
				echo $LOGSTR
				echo $LOGSTR >> ${LOGFILE}
				mv ${INSTCMD} ${INSTCMD}.org
				cp ../${INSTCMD}.${COMPONENT} ${INSTCMD}
				chmod +x ${INSTCMD}
			fi

			echo "=== ${FUNCNAME}: `date`: Running: ${INSTALLCMD}..."
			echo "=== ${FUNCNAME}: `date`: Running: ${INSTALLCMD}..." >> ${LOGFILE}
			cd ${BVTDIR} >> ${LOGFILE} 2>&1
			rm -f ${INSTALLLOG} >> ${LOGFILE} 2>&1
			${INSTALLCMD} >> /dev/null 2>&1
			INSTALLSTATUS=`tail -3l ${BVTDIR}/${INSTALLLOG} | grep Installation | tail -1`
			echo "=== ${FUNCNAME}: Status reported by install:\n${INSTALLSTATUS}"
			echo "=== ${FUNCNAME}: Status reported by install:\n${INSTALLSTATUS}" >> ${LOGFILE}

			echo "=== ${FUNCNAME}: Complete install details in ${BVTDIR}/${INSTALLLOG}"
			echo "=== ${FUNCNAME}: Complete install details in ${BVTDIR}/${INSTALLLOG}" >> ${LOGFILE}
			echo "=== ${FUNCNAME}: Highlights for component ${COMPONENT}:\n" >> ${LOGFILE}
			grep '<<<' ${INSTALLLOG} >> ${LOGFILE} 2>&1
			echo >> ${LOGFILE} 2>&1


			NUMLINES=0
			STARTLINENUM=`grep -n "Total number of components:" ${BVTDIR}/${INSTALLLOG} | sed -e 's,:.*$,,'`
			ENDLINENUM=`wc -l ${BVTDIR}/${INSTALLLOG} | awk '{ print $1}'`
			if [ ! -z "${STARTLINENUM}" -a ! -z "${ENDLINENUM}" ]
			then
				NUMLINES=`echo ${ENDLINENUM}-${STARTLINENUM}+2 | bc`
			fi
			if [ -z "${NUMLINES}" -o "${ENDLINENUM}" = "0" ]
			then
				tail -10l ${BVTDIR}/${INSTALLLOG} >> ${LOGFILE} 2>&1
			else
				tail -${NUMLINES}l ${BVTDIR}/${INSTALLLOG} >> ${LOGFILE} 2>&1
			fi
			echo >> ${LOGFILE} 2>&1


			if [ -z "${INSTALLSTATUS}" ]
			then
				STATUS=FAILED
			else
				INSTALLSTATUS=`echo ${INSTALLSTATUS} | sed -e 's,^.* ,,g'`
				if [ "${INSTALLSTATUS}" != "complete." ]
				then
					STATUS=FAILED
				fi
			fi

			cd ${BVTDIR}
			rm -rf ${EXTRACTDIR}
			cd $ORIGDIR

			echo "=== ${FUNCNAME}: `date`: Done: STATUS=${STATUS} for COMPONENT=${COMPONENT} PROMPTS=${PROMPTS}"
			echo "=== ${FUNCNAME}: `date`: Done: STATUS=${STATUS} for COMPONENT=${COMPONENT} PROMPTS=${PROMPTS}" >> ${LOGFILE}


			if [ ! -z "${DEBUG_FILELIST}" ]
			then
				_TMPFINDLOG=${BVTDIR}/find_log
				if [ "${PROMPTS}" = "${INSTALL_PROMPTS_DK}" ]
				then
					_TMPFINDDIR=${TXINSTALLDIR_DK}
					_TMPFINDLOG=${_TMPFINDLOG}.dk
				else
					_TMPFINDDIR=${TXINSTALLDIR}
				fi
				_TMPFINDLOG=${_TMPFINDLOG}.${COMPONENT}

				echo "=== ${FUNCNAME}: Finding files below ${_TMPFINDDIR}...
				echo "=== ${FUNCNAME}: Finding files below ${_TMPFINDDIR}... >> ${LOGFILE}

				cd ${_TMPFINDDIR}
				find . -type f | sort -f > ${_TMPFINDLOG}
				cd $ORIGDIR

				_TMPFINDDIR=
				_TMPFINDLOG=
			fi

		else
			if [ "${PLATFORM}" = "itanium" -a \
			 	\( \
				  \( "${COMPONENT}" = "adstxbeawl" -o "${COMPONENT}" = "adstxea" -o  \
					 "${COMPONENT}" = "adstxjcag"  -o "${COMPONENT}" = "adstxsc"     \
				  \) -o \
				  \( "${VRMFNUM}" -lt "8202"       -a                                \
				    \( "${COMPONENT}" = "wsdtxmb"  -o "${COMPONENT}" = "wsdtxsac" \) \
				  \) \
				  \) -o \
				  \( "${VRMFNUM}" -lt "8300"       -a "${COMPONENT}" = "wsdtxla"  \) \
				\) ]
			then
				STATUS=WARNING
				echo "=== ${FUNCNAME}: `date`: Done: STATUS=${STATUS}: ${PLATFORM} does not support ${COMPONENT} - ignored"
				echo "=== ${FUNCNAME}: `date`: Done: STATUS=${STATUS}: ${PLATFORM} does not support ${COMPONENT} - ignored" >> ${LOGFILE}
			else
				STATUS=FAILED
				echo "=== ${FUNCNAME}: `date`: Done: STATUS=${STATUS}: Missing tarball=${COMPONENT}_${TARSUFFIX}.tar"
				echo "=== ${FUNCNAME}: `date`: Done: STATUS=${STATUS}: Missing tarball=${COMPONENT}_${TARSUFFIX}.tar" >> ${LOGFILE}
			fi
		fi
	else
		STATUS=FAILED
		echo "=== ${FUNCNAME}: `date`: Done: STATUS=${STATUS}: Missing arg: COMPONENT=\"$1\" PROMPTS=\"$2\""
		echo "=== ${FUNCNAME}: `date`: Done: STATUS=${STATUS}: Missing arg: COMPONENT=\"$1\" PROMPTS=\"$2\"" >> ${LOGFILE}
	fi

	if [ "${STATUS}" = "FAILED" ]
	then
		FINAL_STATUS=FAILED
	fi

	ask_yn

	FUNCNAME=${RIFTB_FUNCNAME}
}



function RunBVTTestCases
{
	RBVTTC_FUNCNAME=${FUNCNAME}
	FUNCNAME=RunBVTTestCases
	STATUS=PASSED
	TESTS_RUN=FALSE

	LOGSTR="\n=== ${FUNCNAME}: `date`: Start: PWD=$PWD"
	echo $LOGSTR
	echo $LOGSTR >> ${LOGFILE}


	if [ -z "${TXINSTALLDIR}" ]
	then
		SetVarFromInstallPromptsFile TXINSTALLDIR ${INSTALL_PROMPTS}
	fi

	if [ -z "${TXINSTALLDIR}" ]
	then
		STATUS=WARNING
		LOGSTR="\n=== ${FUNCNAME}: `date`: STATUS=${STATUS}: TXINSTALLDIR undefined - no tests run"
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}
	elif [ ! -d ${TXINSTALLDIR} ]
	then
		STATUS=WARNING
		LOGSTR="\n=== ${FUNCNAME}: `date`: STATUS=${STATUS}: Missing TXINSTALLDIR=${TXINSTALLDIR} - no tests run"
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}
	else

		LOGSTR="\n=== ${FUNCNAME}: `date`: Start: TXINSTALLDIR=${TXINSTALLDIR}"
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}

		RunTestsUsingDir ${TXINSTALLDIR} 0

		TESTS_RUN=TRUE

		if [ "${STATUS}" = "FAILED" ]
		then
			FINAL_RUN_STATUS=FAILED
		else
			FINAL_RUN_STATUS=PASSED
		fi
	fi


	if [ -z "${TXINSTALLDIR_DK}" ]
	then
		ORIG_TXINSTALLDIR=${TXINSTALLDIR}
		SetVarFromInstallPromptsFile TXINSTALLDIR ${INSTALL_PROMPTS}
		TXINSTALLDIR_DK=${TXINSTALLDIR}
		TXINSTALLDIR=${ORIG_TXINSTALLDIR}
	fi

	if [ -z "${TXINSTALLDIR_DK}" ]
	then
		STATUS=WARNING
		LOGSTR="\n=== ${FUNCNAME}: `date`: STATUS=${STATUS}: TXINSTALLDIR_DK undefined - no tests run"
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}
	elif [ ! -d ${TXINSTALLDIR_DK} ]
	then
		STATUS=WARNING
		LOGSTR="\n=== ${FUNCNAME}: `date`: STATUS=${STATUS}: Missing TXINSTALLDIR_DK=${TXINSTALLDIR_DK} - no tests run"
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}
	else

		LOGSTR="\n=== ${FUNCNAME}: `date`: Start: TXINSTALLDIR_DK=${TXINSTALLDIR_DK}"
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}

		RunTestsUsingDir ${TXINSTALLDIR_DK} 1


		if [ "${STATUS}" = "FAILED" ]
		then
			FINAL_RUN_STATUS=FAILED
		elif [ "${TESTS_RUN}" = "FALSE" ]
		then
			FINAL_RUN_STATUS=PASSED
		fi
	fi

	LOGSTR="\n=== ${FUNCNAME}: `date`: Done: BVTDIR=${BVTDIR} FINAL_RUN_STATUS=${FINAL_RUN_STATUS}"
	echo $LOGSTR
	echo $LOGSTR >> ${LOGFILE}

	FUNCNAME=${RBVTTC_FUNCNAME}
}



function RunTestsUsingDir
{
	RTUD_FUNCNAME=${FUNCNAME}
	FUNCNAME=RunTestsUsingDir

	if [ ! -z "$1" -a -d "$1" ]
	then
		INSTALLDIR=$1
		if [ "$2" = "1" ]
		then
			RUN_DK_TESTS=TRUE
		else
			RUN_DK_TESTS=FALSE
		fi

		TXSETUPFILE=${INSTALLDIR}/setup
		if [ -f ${TXSETUPFILE} ]
		then
			LOGSTR="=== ${FUNCNAME}: `date`: Setting WTX environment..."
			echo $LOGSTR
			echo $LOGSTR >> ${LOGFILE}
			. ${TXSETUPFILE} >> ${LOGFILE}
		fi

		if [ -z "${DTX_HOME_DIR}" ]
		then
			if [ ! -z "${MERC_HOME_DIR}" ]
			then
				DTX_HOME_DIR=${MERC_HOME_DIR}
			fi
		fi

		if [ ! -z "${DTX_HOME_DIR}" ]
		then
			if [ "${RUN_DK_TESTS}" = "TRUE" ]
			then
				ExecuteDK Example1.java ${DTX_HOME_DIR}/examples/dk/dtxpi/java
			else
				ExecuteMap sinkmap ${DTX_HOME_DIR}/examples/general/map/sinkmap

				CURRTESTDIR=${BVTTESTDIR}/IPO
				rm -f ${CURRTESTDIR}/output.xml
				ExecuteMap test ${CURRTESTDIR}
				ls -lt ${CURRTESTDIR}/output.xml | head -10 >> ${LOGFILE} 2>&1
			fi
		else
			STATUS=FAILED
			LOGSTR="=== ${FUNCNAME}: `date`: Error: DTX_HOME_DIR undefined after setting WTX environment"
			echo $LOGSTR
			echo $LOGSTR >> ${LOGFILE}
		fi
	fi
	FUNCNAME=${RTUD_FUNCNAME}
}



function ExecuteMap
{
	FUNCNAME=ExecuteMap
	EM_FUNCNAME=${FUNCNAME}
	EM_STATUS=FAILED

	if [ ! -z "$1" -a ! -z "$2" ]
	then
		TESTCASE=$1
		TESTCASEDIR=$2

		LOGSTR="=== ${FUNCNAME}: `date`: Attempting TESTCASE=${TESTCASE} in ${TESTCASEDIR}"
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}

		COMPILEDMAP=
		if [ -d ${TESTCASEDIR} ]
		then
			cd ${TESTCASEDIR}
			if [ -f ${TESTCASE} ]
			then
				COMPILEDMAP=${TESTCASE}
			elif [ -f ${TESTCASE}.${PLATEXT} ]
			then
				COMPILEDMAP=${TESTCASE}.${PLATEXT}
			elif [ -f ${TESTCASE}.mmc ]
			then
				COMPILEDMAP=${TESTCASE}.mmc
			fi
		fi

		if [ -f ${TESTCASEDIR}/${COMPILEDMAP} ]
		then
			EXECMAPCMD="dtxcmdsv ${COMPILEDMAP}"
			# ${EXECMAPCMD} | sed -e 's,^. Copyright,Copyright,' >> ${LOGFILE} 2>&1
			${EXECMAPCMD} >> ${LOGFILE} 2>&1
			RETCODE=$?
			if [ "${RETCODE}" = "0" ]
			then
				EM_STATUS=PASSED
			fi
			LOGSTR="=== ${FUNCNAME}: `date`: STATUS=${EM_STATUS}: EXECMAPCMD=\"${EXECMAPCMD}\" returned ${RETCODE}"
			echo $LOGSTR
			echo $LOGSTR >> ${LOGFILE}
		else
			EM_STATUS=FAILED
			LOGSTR="=== ${FUNCNAME}: `date`: STATUS=${EM_STATUS}: Missing testcase: TESTCASE=\"${TESTCASE}\" TESTCASEDIR=\"${TESTCASEDIR}\""
			echo $LOGSTR
			echo $LOGSTR >> ${LOGFILE}
		fi
	else
		LOGSTR="=== ${FUNCNAME}: `date`: STATUS=${STATUS}: Bad testcase: Arg1=\"$1\" Arg2=\"$2\""
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}
	fi

	if [ "${EM_STATUS}" = "FAILED" ]
	then
		STATUS=FAILED
	fi

	FUNCNAME=${EM_FUNCNAME}
}



function ExecuteDK
{
	FUNCNAME=ExecuteDK
	EDK_FUNCNAME=${FUNCNAME}
	EDK_STATUS=FAILED

	if [ ! -z "$1" -a ! -z "$2" ]
	then
		TESTCASE=$1
		TESTCASEDIR=$2

		EDK_STATUS=WARNING
		LOGSTR="=== ${FUNCNAME}: `date`: STATUS=${EDK_STATUS}: TODO: Attempt DK TESTCASE=${TESTCASE} in ${TESTCASEDIR}"
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}
	else
		LOGSTR="=== ${FUNCNAME}: `date`: STATUS=${EDK_STATUS}: Bad DK testcase: Arg1=\"$1\" Arg2=\"$2\""
		echo $LOGSTR
		echo $LOGSTR >> ${LOGFILE}
	fi

	if [ "${EDK_STATUS}" = "FAILED" ]
	then
		STATUS=FAILED
	fi

	FUNCNAME=${EDK_FUNCNAME}
}



function ParseDtxIni_EnableIgnoreGPFs
{
	INIFILE=dtx.ini
	VRNUM=`echo "${VRMFNUM}" | sed -e "s/^80.*$/80/"`
	if [ "${VRNUM}" = "80" ]
	then
		INIFILE=dstx.ini
	fi

	INIFILE=$1/config/${INIFILE}
	if [ -f ${INIFILE} ]
	then
		grep "^;IgnoreGPFs=" ${INIFILE} > /dev/null 2>&1
		if [ $? = 0 ]
		then
			echo $0: `date`: Enabling IgnoreGPFs in "${INIFILE}"
			ORIG_INIFILE=${INIFILE%.ini}.org
			if [ ! -f ${ORIG_INIFILE} ]
			then
				cp -p ${INIFILE} ${ORIG_INIFILE}
			fi

			TMP_INIFILE=${INIFILE%.ini}.tmp
			rm -f ${TMP_INIFILE}
			sed -e "s/^;IgnoreGPFs=/IgnoreGPFs=/" ${INIFILE} > ${TMP_INIFILE}
			cp -p ${TMP_INIFILE} ${INIFILE}
			rm -f ${TMP_INIFILE}
		fi
	else
		echo $0: `date`: INI file not found: "${INIFILE}"
	fi
}



function DtxIni_EnableIgnoreGPFs
{
	if [ ! -z "${TXINSTALLDIR}" ]
	then
		if [ -d ${TXINSTALLDIR} ]
		then
			ParseDtxIni_EnableIgnoreGPFs ${TXINSTALLDIR}
		fi
	fi

	if [ ! -z "${TXINSTALLDIR_DK}" ]
	then
		if [ -d ${TXINSTALLDIR_DK} ]
		then
			ParseDtxIni_EnableIgnoreGPFs ${TXINSTALLDIR_DK}
		fi
	fi
}



PROGNAME="`echo $0 | sed -e 's,^.*/,,g'` (v${FILE_REV})"
LOGFILE=
if [ "$1" = "BVTTestsOnly" ]
then
	RUN_TESTS_ONLY=TRUE
fi

################################################################################
#
# List of variables that can be set in the environment to control script
# execution.  Look inside this function for the current default values
# being used.
#
# VRMFNUM: Version.Release.Maintenance.FixLevel - Used to determine the name
#          of the tar images for each release.
#
# BITTYPE: 32 or 64.  Used to determine the name of the tar images for each
#          release.
#
# BVTDIR: Base directory for storing results.
#
# INSTALL_PROMPTS: Path to file with install prompts for core installs.
#
# INSTALL_PROMPTS_DK: Path to file with install prompts for DK installs.
#
# TXINSTALLS_CORE: String listing the base name of the core installs to run.
# - To apply the default set of installs => export TXINSTALLS_CORE=""
# - To apply specific installs =>
#       export TXINSTALLS_CORE="wsdtxcs wsdtxl wsdtxls wsdtxis"
# - To apply no installs => export TXINSTALLS_CORE="none"
#
# TXINSTALLS_DK: String listing the base name of the DK installs to run.
# - To apply the default set of installs => export TXINSTALLS_DK=""
# - To apply specific installs => export TXINSTALLS_DK="wsdtxapi"
# - To apply no installs => export TXINSTALLS_DK="none"
#
# TXINSTALLS_INTERIMFIX: List of InterimFix installs to be applied.  For example:
# - To apply only IF01+IF02 => export TXINSTALLS_INTERIMFIX="01 02"
# - To apply only IF02 => export TXINSTALLS_INTERIMFIX="02"
# - To apply no IF => export TXINSTALLS_INTERIMFIX="none"
#
################################################################################

################################################################################
# Begin: Modify these variables to customize your install.
################################################################################


################################################################################
# End: Modify these variables to customize your install.
################################################################################

InitializeEnv

MakeDirectory ${BVTDIR}

if [ ! -d "${BVTDIR}" ]
then
	FINAL_STATUS=FAILED
	FINAL_STATUS_STRING="=== ${PROGNAME}: `date`: Done: Error: Missing BVTDIR=${BVTDIR} - FINAL_STATUS=${FINAL_STATUS}"
elif [ "${RUN_TESTS_ONLY}" = "TRUE" ]
then
	LOGFILE=${BVTDIR}/bvttest_log.all
	DumpSettings > ${LOGFILE}
	RunBVTTestCases

	FINAL_STATUS_STRING="\n=== ${PROGNAME}: `date`: Done: BVTDIR=${BVTDIR} FINAL_RUN_STATUS=${FINAL_RUN_STATUS}"
else
	LOGFILE=${BVTDIR}/install_log.all

	cd ${BVTDIR}

	DumpSettings > ${LOGFILE}


	if [ ! -z "${TXINSTALLDIR}" -o ! -f ${INSTALL_PROMPTS} ]
	then
		GenerateInstallPromptFiles ${INSTALL_PROMPTS}    0
	else
		SetVarFromInstallPromptsFile TXINSTALLDIR ${INSTALL_PROMPTS}
	fi

	if [ ! -z "${TXINSTALLDIR_DK}" -o ! -f ${INSTALL_PROMPTS_DK} ]
	then
		GenerateInstallPromptFiles ${INSTALL_PROMPTS_DK} 1
	else
		ORIG_TXINSTALLDIR=${TXINSTALLDIR}
		SetVarFromInstallPromptsFile TXINSTALLDIR ${INSTALL_PROMPTS_DK}
		TXINSTALLDIR_DK=${TXINSTALLDIR}
		TXINSTALLDIR=${ORIG_TXINSTALLDIR}
	fi

	for comp in ${INSTALLS_TOAPPLY_CORE}
	do
		RunInstallFromTarball ${comp} ${INSTALL_PROMPTS}
	done

	for comp in ${INSTALLS_TOAPPLY_DK}
	do
		RunInstallFromTarball ${comp} ${INSTALL_PROMPTS_DK}
	done


	for INTFIXLVL in ${INSTALLS_TOAPPLY_INTERIMFIX}
	do
		if [ ! -z "${TXINSTALLDIR}" -a -d ${TXINSTALLDIR} ]
		then
			RunInstallFromTarball wsdtxif${INTFIXLVL} ${INSTALL_PROMPTS}
		fi

		if [ ! -z "${TXINSTALLDIR_DK}" -a -d ${TXINSTALLDIR_DK} ]
		then
			RunInstallFromTarball wsdtxif${INTFIXLVL} ${INSTALL_PROMPTS_DK}
		fi
	done

	if [ ! -z "${TXINSTALLS_DPFILES}" ]
	then
		INSTALLLOG_DP=${BVTDIR}/install_log.dpwr
		DP_STATUS=PASSED
		echo "=== ${PROGNAME}: `date`: Start: Installing DataPower files\n\n" > ${INSTALLLOG_DP}
		for DPFILE in ${TXINSTALLS_DPFILES}
		do
			BASENAME=`echo ${DPFILE} | sed 's/.gz//g'`
			if [ -f ${TARBALLDIR}/${BASENAME}.gz ]
			then
				echo "=== Unzipping DataPower file ${BASENAME}.gz" >> ${INSTALLLOG_DP}
				gunzip ${TARBALLDIR}/${BASENAME}.gz >> ${INSTALLLOG_DP} 2>&1
			fi 
			if [ ! -d ${TXINSTALLDIR} ]
			then
				mkdir -p ${TXINSTALLDIR}
			fi
			echo "=== Extracting DataPower file ${BASENAME} to ${TXINSTALLDIR}" >> ${INSTALLLOG_DP}
			tar -xvf ${TARBALLDIR}/${BASENAME} -C ${TXINSTALLDIR} >> ${INSTALLLOG_DP} 2>&1
			if [ $? != 0 ]
			then
				FINAL_STATUS=FAILED
				DP_STATUS=FAILED
			fi
			echo "=== Extract DataPower files: Done: STATUS=${DP_STATUS} for file ${TARBALLDIR}/${BASENAME}" >> ${INSTALLLOG_DP}
		done
		echo "\n\n=== ${PROGNAME}: `date`: Done: Installing DataPower files" >> ${INSTALLLOG_DP}
		cat ${INSTALLLOG_DP}
	fi

	if [ "${TXINSTALLS_NOENABLEGPFS}" != "1" ]
	then
		DtxIni_EnableIgnoreGPFs
	fi

	FINAL_STATUS_STRING="\n=== ${PROGNAME}: `date`: Done: BVTDIR=${BVTDIR} FINAL_STATUS=${FINAL_STATUS}"
fi

if [ ! -z "${FINAL_STATUS_STRING}" ]
then
	echo ${FINAL_STATUS_STRING}
	if [ ! -z "${LOGFILE}" ]
	then
		echo ${FINAL_STATUS_STRING} >> ${LOGFILE}
	fi
fi
