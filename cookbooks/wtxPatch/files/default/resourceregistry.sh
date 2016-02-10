#!/bin/ksh
##########################################################################
# == Licensed Materials - Property of IBM
# == 5724-Q23
# == © Copyright IBM Corporation 1994, 2011
##########################################################################
# Copyright (C) 2005 Ascential Software Corporation. All Rights Reserved.
# 
# This is unpublished proprietary source code of Ascential Software, Inc.
# The copyright notice above does not evidence any actual or intended
# publication of such source code.
#########################################################################


##PATCHED BY CHEF ## 

. $DTX_HOME_DIR/bin/common.sh

if [[ $? -ne 0 ]]; then
    echo "Must run envsetup script prior to running this script."
    exit 1
fi


CLASSPATH=$DTX_JARS_DIR/resourceregistry.jar:$CLASSPATH

export CLASSPATH

#$JAVA -Duser.language=$USRLANGUAGE -Duser.country=$USRCOUNTRY com.ibm.websphere.dtx.resourceregistry.gui.ResourceRegistry &
$JAVA com.ibm.websphere.dtx.resourceregistry.gui.ResourceRegistry &

