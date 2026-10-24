# SELinux: Fedora / RHEL-family alternate path

Commands only. The course uses no custom policy modules.

```bash
getenforce                                   # Enforcing
ls -Z /var/www/html /srv/site                # file labels
ps -eZ | grep nginx                          # process domain (httpd_t)
sudo ausearch -m avc -ts recent              # recent denials
sudo semanage fcontext -a -t httpd_sys_content_t '/srv/site(/.*)?'
sudo restorecon -Rv /srv/site                # apply the persistent rule
sudo chcon -R -t httpd_sys_content_t /srv/site   # temporary; undone by restorecon
getsebool httpd_can_network_connect
sudo setsebool -P httpd_can_network_connect 1    # nginx may connect to upstreams (Lab 12.1)
sudo semanage port -l | grep http_port_t
sudo semanage port -a -t http_port_t -p tcp 8088 # only if 8088 is not already labelled
sudo ausearch -m avc -ts recent | audit2why
```

Files moved with `mv` keep their old label. Use `install` or `cp`, or run `restorecon -v` on the target.
