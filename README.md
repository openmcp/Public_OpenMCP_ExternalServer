# OpenMCP External Server

## Introduction of OpenMCP External Server

> KETI에서 개발한 OpenMCP 플랫폼의 NFS, DNS, ETCD복제의 기능을 위한 외부 서버

## Requirement
> Ubuntu 16.04 


## How to Install
```
# NFS 설치
cd nfs_installer
./install.sh

# ETCD 설치
cd etcd_installer
./install.sh

# PowerDNS 설치
cd powerdns_installer
./install.sh
```

## Install Check

> NFS, ETCD, PowerDNS 설치 확인
```
# NFS
MY_ADDRESS=`ip route get 8.8.8.8 | head -1 | cut -d' ' -f8` # 본인 IP 조회
mkdir test_nfs # 테스트 디렉토리 생성
mount -t nfs $MY_ADDRESS:/home/nfs test_nfs # NFS 마운트
df -h | grep test_nfs # 마운트된 NFS정보 확인
umount test_nfs # 마운트 해제
rm -r test_nfs # 테스트 디렉토리 삭제


# ETCD
# Service 가동여부 확인(Activate: activate이면 성공)
systemctl status etcd
systemctl status etcd_clone

# PowerDNS
# Service 가동 여부 확인
systemctl status pdns
systemctl status pdns-recursor
systemctl status powerdns-admin

# URL 접속 확인
MY_ADDRESS=`ip route get 8.8.8.8 | head -1 | cut -d' ' -f8` # 본인 IP 조회
http://$MY_ADDRESS:8081 # PDNS Server
http://$MY_ADDRESS # PowerDNS Web UI(PwerDNS-admin)

```

## Governance

본 프로젝트는 정보통신기술진흥센터(IITP)에서 지원하는 '19년 정보통신방송연구개발사업으로, "컴퓨팅 자원의 유연한 확장 및 서비스 이동을 제공하는 분산·협업형 컨테이너 플랫폼 기술 개발 과제" 임.
