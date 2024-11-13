# https://hub.docker.com/_/almalinux
ARG VARIANT="8.10"
FROM almalinux:${VARIANT}

RUN dnf update -y \
    && dnf install -y epel-release \
    && dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo \
    && dnf install -y --enablerepo=epel \
        glibc-langpack-ja \
        glibc-locale-source \
        procps \
        sudo \
        git \
        openssh-server \
        supervisor \
        wget \
        zip \
        nano \ 
        htop \
        docker-ce-cli

# ロケール及びタイムゾーンを日本に設定
RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8 \
    && echo 'LANG=ja_JP.UTF-8' > /etc/locale.conf \
    && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8" \
    TZ="Asia/Tokyo"

# 諸々の開発ツールのインストール先
ARG DEV_TOOLS_DIR="/opt/dev-tools"

# .NET SDK のインストール ※要 libicu
ARG DOTNET_VERSION \
    DOTNET_HOME="${DEV_TOOLS_DIR}/dotnet"
RUN dnf install -y \
        libicu \ 
    && wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x ./dotnet-install.sh \
    && mkdir -p "${DOTNET_HOME}" \
    && ./dotnet-install.sh --version ${DOTNET_VERSION} --install-dir "${DOTNET_HOME}" \
    && rm ./dotnet-install.sh \
    && echo "export PATH=\$PATH:${DOTNET_HOME}" > /etc/profile.d/dotnet_path.sh

# dotnet コマンドの製品利用統計情報機能をオプトアウト
RUN echo "export DOTNET_CLI_TELEMETRY_OPTOUT=1" > /etc/profile.d/dotnet_cli_telemetry_optout.sh

# 一般ユーザー追加 
ARG USER_NAME \
    USER_PASSWORD \
    USER_UID \
    USER_GID
RUN groupadd --gid ${USER_GID} ${USER_NAME} \
    && useradd \
        --shell /bin/bash \
        --create-home \
        --home-dir /home/${USER_NAME} \
        --uid ${USER_UID} \
        --gid ${USER_GID} \
        ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME} \
    && echo "${USER_NAME}:${USER_PASSWORD}" | chpasswd

# Docker グループの GID 変更とユーザー追加
ARG DOCKER_GID
RUN groupmod -g ${DOCKER_GID} docker \
    && usermod -aG docker ${USER_NAME}

# 追加したユーザーのホーム内に .vscode-server フォルダ作成 ※永続化用
RUN mkdir "/home/${USER_NAME}/.vscode-server" \
    && chown ${USER_UID}:${USER_GID} "/home/${USER_NAME}/.vscode-server"

# 追加したユーザーを諸々の開発ツールのインストール先のオーナーに設定
RUN chown -R ${USER_UID}:${USER_GID} "${DEV_TOOLS_DIR}" \
    && chmod -R 775 "${DEV_TOOLS_DIR}"

# 追加したユーザーのホーム内に setup_vscode.sh を配置
COPY setup_vscode.sh "/home/${USER_NAME}/setup_vscode.sh"
COPY vscode_setup_files "/home/${USER_NAME}/vscode_setup_files"
RUN chown ${USER_UID}:${USER_GID} "/home/${USER_NAME}/setup_vscode.sh" \
    && chmod +x "/home/${USER_NAME}/setup_vscode.sh" \
    && chown ${USER_UID}:${USER_GID} "/home/${USER_NAME}/vscode_setup_files" \
    && chmod +x -R "/home/${USER_NAME}/vscode_setup_files"

# 追加したユーザーのホーム内に projects フォルダ作成 ※永続化用
RUN mkdir "/home/${USER_NAME}/projects" \
    && chown ${USER_UID}:${USER_GID} "/home/${USER_NAME}/projects"

# Entrypoint
COPY entrypoint.d /entrypoint.d
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh \
    && chmod +x -R /entrypoint.d

# Supervisor
ENV VSCODE_USER="${USER_NAME}" \
    VSCODE_INSTALL_DIR="${VSCODE_INSTALL_DIR}" \
    VSCODE_SERVER_DATA_DIR="${VSCODE_SERVER_DATA_DIR}" \
    VSCODE_USER_DATA_DIR="${VSCODE_USER_DATA_DIR}" \
    VSCODE_EXTENSIONS_DIR="${VSCODE_EXTENSIONS_DIR}" \
    VSCODE_CLI_DATA_DIR="${VSCODE_CLI_DATA_DIR}"
COPY supervisord.conf /etc/supervisor/
RUN mkdir -p /var/run/supervisor /var/log/supervisor \
    && chmod -R 755 /var/run/supervisor /var/log/supervisor

# 起動時の設定
EXPOSE 22
ENTRYPOINT ["sudo", "-E", "/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}
