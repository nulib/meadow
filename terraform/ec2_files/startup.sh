#!/bin/bash

# Install required software
amazon-linux-extras install epel -y
yum update -y
yum install -y amazon-cloudwatch-agent autoconf curl dirmngr fop gawk git gpg htop \
               inotify-tools jq libxslt ncurses-devel openssl-devel tmux postgresql \
               wxGTK3-devel wxBase3 
yum groupinstall -y 'Development Tools' 'C Development Tools and Libraries'

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf ./aws
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
yum install -y session-manager-plugin.rpm
rm -f session-manager-plugin.rpm
aws configure set region us-east-1
cd -

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

# Install erlang, Elixir, and NodeJS
for lang in erlang elixir nodejs; do
  asdf plugin add $lang
done

bash -c '$${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'

asdf install erlang ${erlang_version}
asdf global erlang ${erlang_version}
asdf install elixir ${elixir_version}
asdf global elixir ${elixir_version}
asdf install nodejs ${nodejs_version}
asdf global nodejs ${nodejs_version}
npm install -g npm@latest

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

command="bin/meadow remote"
task_id=$(aws ecs list-tasks --cluster meadow --service meadow | jq -r '.taskArns[0] | split("/") | last')
echo "Running \`$${command}\` on task $${task_id}"
aws ecs execute-command --cluster meadow --container meadow --interactive --command "$${command}" --task $${task_id}
__END__

chmod 0755 /home/ec2-user/bin/iex-remote
__EOF__

chmod 0755 /tmp/user_setup.sh
sudo su ec2-user /tmp/user_setup.sh
