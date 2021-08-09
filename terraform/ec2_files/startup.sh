#!/bin/bash

# Install required software
amazon-linux-extras install epel -y
yum update -y
yum install -y amazon-cloudwatch-agent autoconf curl dirmngr fop gawk git gpg htop \
               inotify-tools jq libxslt ncurses-devel openssl-devel tmux postgresql-9.2.24 \
               wxGTK3-devel wxBase3 
yum groupinstall -y 'Development Tools' 'C Development Tools and Libraries'

# Set up log stream
mkdir -p /var/log/meadow
chown ec2-user:ec2-user /var/log/meadow

mkdir /etc/amazon-cloudwatch-agent
cat > /etc/amazon-cloudwatch-agent/config.json <<'__EOF__'
{
  "agent": {
    "run_as_user": "cwagent"
  },
  "logs": {
    "force_flush_interval": 5,
    "logs_collected": {
      "files": {
        "collect_list": [{
            "file_path": "/var/log/meadow/meadow.log",
            "log_group_name": "/ec2/meadow",
            "log_stream_name": "{instance_id}",
            "multi_line_start_pattern": "{timestamp_format}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S.%f",
            "timezone": "LOCAL"
          }
        ]
      }
    }
  }
}
__EOF__

cat >> /etc/logrotate.d/meadow <<'__EOF__'
/var/log/meadow/meadow.log {
    missingok
    notifempty
    size 100M
    create 0600 ec2-user ec2-user
    delaycompress
    compress
    rotate 4
    postrotate
        systemctl restart awslogsd
    endscript
}
__EOF__

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/etc/amazon-cloudwatch-agent/config.json
systemctl enable amazon-cloudwatch-agent.service

# Create and run the user initialization script
cat > /tmp/user_setup.sh <<'__EOF__'
#!/bin/bash

# Install ssh keys for authorized users
rm $HOME/.ssh/authorized_keys
touch $HOME/.ssh/authorized_keys
chmod 0600 /home/ec2-user/.ssh/authorized_keys

for u in ${ec2_instance_users}; do
  curl -s https://github.com/$${u}.keys | awk "{print \$1, \$2, \"$u\"}" >> $HOME/.ssh/authorized_keys
done

# Install asdf
git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.8.0
. $HOME/.asdf/asdf.sh

# Install erlang, Elixir, NodeJS, and Yarn
for lang in erlang elixir nodejs yarn; do
  asdf plugin add $lang
done

bash -c '$${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'

for lang in erlang elixir nodejs yarn; do
  asdf install $lang latest
  asdf global $lang $(asdf list $lang)
done

# Update login script
echo '. $HOME/.asdf/asdf.sh' >> $HOME/.bashrc
echo '. $HOME/.meadowrc' >> $HOME/.bashrc

# Clone and configure Meadow
cd $HOME
git clone https://github.com/nulib/meadow.git

cat > $HOME/.meadowrc <<'__END__'
${meadow_rc}
__END__

cat > $HOME/meadow/config/dev.local.exs <<'__END__'
${dev_local_exs}
__END__

. $HOME/.meadowrc
cd $HOME/meadow
mix local.hex --force
mix local.rebar --force
mix do deps.get, deps.compile, compile, assets.install

# Create the iex-remote script
mkdir -p /home/ec2-user/bin
cat > /home/ec2-user/bin/iex-remote <<'__END__'
#!/bin/bash

target_ip=$(aws --region $${AWS_REGION} elbv2 describe-target-health --target-group-arn ${target_group_arn} --query 'TargetHealthDescriptions[*].Target.Id' | jq -r '.[0]')
iex --name "$(whoami)@$(hostname)" --remsh "meadow@$target_ip" --cookie $SECRET_KEY_BASE
__END__

chmod 0755 /home/ec2-user/bin/iex-remote
__EOF__

chmod 0755 /tmp/user_setup.sh
sudo su ec2-user /tmp/user_setup.sh
