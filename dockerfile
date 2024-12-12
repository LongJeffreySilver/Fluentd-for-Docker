#sudo docker build -t fluentd_prueba:latest .

FROM fluentd:v1.18.0-debian-1.0

USER root

# Instalar dependencias de compilación (Debian)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ruby-dev \
    libsystemd-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalamos plugins necesarios:
# - fluent-plugin-systemd: para leer logs de systemd
# - fluent-plugin-docker_metadata_filter: para procesar metadatos de contenedores Docker
# - fluent-plugin-prometheus: para exponer un endpoint con metricas en formato Prometheus
# - fluent-plugin-metrics: para extraer metricas de salud del host como el uso de cpu o la memoria -> NO FUNCIONA YA :C
RUN gem install fluent-plugin-systemd fluent-plugin-docker_metadata_filter fluent-plugin-prometheus 

# Creamos el directorio de configuración si no existe y ponemos los permisos al root.
#Usuario fluent quitado -> RUN mkdir -p /fluentd/log && chown fluent:fluent /fluentd/log
RUN mkdir -p /fluentd/log && chown root:root /fluentd/log
RUN mkdir -p /fluentd/etc

# Copiamos nuestro archivo de configuración local (fluent.conf) al contenedor
COPY fluent.conf /fluentd/etc/

# Ajustamos permisos
RUN chown root:root /fluentd/etc/fluent.conf

#Eliminamos la parte del usuario fluent porque no tiene permisos dentro del contenedor para leer /var/log/syslog. Por lo tanto el usuario actual seguirá siendo root. Recordemos que el contenedor tiene el log montado con "ro" desde el host, pero root puede leerlo sin inconveniente.
#RUN chown fluent:fluent /fluentd/etc/fluent.conf
#USER fluent

# Ejecutamos Fluentd con la configuración proporcionada
CMD ["fluentd", "-c", "/fluentd/etc/fluent.conf", "-p", "/fluentd/plugins", "--no-supervisor", "-vv"]

