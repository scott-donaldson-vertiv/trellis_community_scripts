
Front Server
------------

Install Service

  cd <MOD_LOCATION>
  cp ./trellis_custom_ssh /etc/init.d/
  chmod +x /etc/init.d/trellis_custom_ssh
  chkconfig add /etc/init.d/trellis_custom_ssh
  cp ./trellis_custom_ssh.conf /etc/default/

Validate Firewall Rules

  chmod +x ./trellis_custom_iptables-front.sh
  ./trellis_custom_iptables-front.sh

Persist Firewall Rules

  /usr/bin/iptables-save
  
Back Server
-----------

Validate Firewall Rules

  chmod +x ./trellis_custom_iptables-back.sh
  ./trellis_custom_iptables-back.sh

Persist Firewall Rules

  /usr/bin/iptables-save