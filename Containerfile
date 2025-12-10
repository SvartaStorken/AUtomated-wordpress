FROM registry.redhat.io/ubi10/ubi:latest

Run dnf install -y mariadb-server mariadb && \
    dnf clean all

EXPOSE 3306

CMD ["/usr/sbin/mariadbd"]