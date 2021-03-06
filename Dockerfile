FROM centos:centos7

# Do this to enable Oracle Linux
# wget http://public-yum.oracle.com/docker-images/OracleLinux/OL7/oraclelinux-7.0.tar.xz
# docker load -i oraclelinux-7.0.tar.xz
# FROM oraclelinux:7.0

RUN yum -y install hostname.x86_64 rubygems ruby-devel gcc
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc

RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs && \
    rpm -ivh http://yum.puppetlabs.com/el/7/products/x86_64/puppetlabs-release-7-10.noarch.rpm

# configure & install puppet
RUN yum install -y --skip-broken puppet tar
RUN gem install puppet librarian-puppet

RUN yum clean all

ADD puppet/Puppetfile /etc/puppet/
ADD puppet/manifests/site.pp /etc/puppet/
ADD puppet/hiera.yaml /etc/puppet/
ADD puppet/hieradata/common.yaml /etc/puppet/

WORKDIR /etc/puppet/
RUN librarian-puppet install

# upload software
RUN mkdir /var/tmp/install
RUN chmod 777 /var/tmp/install

RUN mkdir /software
RUN chmod 777 /software

COPY jdk-7u55-linux-x64.tar.gz /software/
COPY fmw_12.1.3.0.0_wls.jar /var/tmp/install/

RUN puppet apply /etc/puppet/site.pp --verbose --detailed-exitcodes || [ $? -eq 2 ]

WORKDIR /

# cleanup
RUN rm -rf /software/*
RUN rm -rf /var/tmp/install/*
RUN rm -rf /var/tmp/*
RUN rm -rf /tmp/*

EXPOSE 5556 7001 8001

ADD startWls.sh /
RUN chmod 0755 /startWls.sh

CMD bash -C '/startWls.sh';'bash'
