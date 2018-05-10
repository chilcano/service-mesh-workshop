FROM python:2-onbuild

RUN mkdir -p /opt/microservices
ADD app.py /opt/microservices/

EXPOSE 5000

ARG service_version
ENV SERVICE_VERSION ${service_version:-v1}

WORKDIR /opt/microservices
CMD python app.py
