FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y ffmpeg cron curl

ADD scripts /scripts
RUN chmod +x /scripts/*.sh
RUN chown -R ubuntu:ubuntu /scripts

COPY cron_config /etc/cron.d/cron_config
RUN chmod 0644 /etc/cron.d/cron_config
RUN touch /var/log/cron.log
RUN chown ubuntu:ubuntu /var/log/cron.log

ENV TZ=America/New_York

# Make sure cron scripts can use the environment variables
# Start cron and keep the container running by tailing the cron log
CMD ["/bin/bash", "-c", "printenv > /etc/container_environment && cron -f & su ubuntu -c 'tail -f /var/log/cron.log'"]
