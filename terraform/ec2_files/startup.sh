#!/bin/bash

amazon-linux-extras install epel -y
yum update -y
yum install -y amazon-cloudwatch-agent autoconf curl dirmngr fop gawk git gpg htop \
               inotify-tools jq libxslt ncurses-devel openssl-devel tmux postgresql-9.2.24 \
               wxGTK3-devel wxBase3 
yum groupinstall -y 'Development Tools' 'C Development Tools and Libraries'

cat > /tmp/user_setup.sh <<'__EOF__'
#!/bin/bash

rm $HOME/.ssh/authorized_keys
touch $HOME/.ssh/authorized_keys
chmod 0600 /home/ec2-user/.ssh/authorized_keys

for u in ${ec2_instance_users}; do
  curl -s https://github.com/$${u}.keys | awk "{print \$1, \$2, \"$u\"}" >> $HOME/.ssh/authorized_keys
done

git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.8.0
. $HOME/.asdf/asdf.sh

for lang in erlang elixir nodejs yarn; do
  asdf plugin add $lang
done

bash -c '$${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'

for lang in erlang elixir nodejs yarn; do
  asdf install $lang latest
  asdf global $lang $(asdf list $lang)
done

cd $HOME
git clone https://github.com/nulib/meadow.git

cat > $HOME/.meadowrc <<'__END__'
${meadow_rc}
__END__

cat > $HOME/meadow/config/dev.local.exs <<'__END__'
${dev_local_exs}
__END__

echo '. $HOME/.asdf/asdf.sh' >> $HOME/.bashrc
echo '. $HOME/.meadowrc' >> $HOME/.bashrc

. $HOME/.meadowrc
cd $HOME/meadow
mix local.hex --force
mix local.rebar --force
mix do deps.get, deps.compile, compile, assets.install
__EOF__

chmod 0755 /tmp/user_setup.sh
sudo su ec2-user /tmp/user_setup.sh
