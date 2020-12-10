#!/bin/bash

rpm_topdir=/tmp/mybuildtest
rpm -ivh $rpm_topdir/RPMS/*/*rpm 

systemctl enable --now rshim
systemctl status rshim

sleep infinity
