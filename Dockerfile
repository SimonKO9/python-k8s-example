FROM python:3.10-slim

WORKDIR /code

ENV APP_USERNAME=docker-user
ENV APP_GROUPNAME=$APP_USERNAME
ENV APP_USER_UID=1001
ENV APP_USER_GID=$APP_USER_UID

COPY ./requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir --upgrade -r /code/requirements.txt \
    && python -m pip uninstall -y pip setuptools

COPY ./app /code/app

RUN groupadd --gid $APP_USER_GID $APP_GROUPNAME \
    && useradd --uid $APP_USER_UID --gid $APP_USER_GID --create-home $APP_USERNAME \
    && chown -R $APP_USER_UID:$APP_USER_GID /code

# Additional uvicorn configuration possible with env vars:
# https://www.uvicorn.org/settings/#settings
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80", "--proxy-headers"]

EXPOSE 80