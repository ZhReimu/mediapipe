FROM ubuntu:22.04

ENV USER=ubuntu

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# 换源
# RUN sed -i 's|http://security.ubuntu.com|http://mirrors.tuna.tsinghua.edu.cn|g; s|http://archive.ubuntu.com|http://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils ca-certificates && apt-get -y upgrade \
    && apt-get -y --no-install-recommends install sudo vim wget curl jq git bzip2 make cmake automake autoconf libtool pkg-config clang-format

RUN useradd --create-home -s /bin/bash -m $USER && echo "$USER:$USER" | chpasswd && adduser $USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/$USER
USER ubuntu

RUN sudo apt-get install unzip python3-pip openjdk-17-jdk -y

ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
ENV PATH="$PATH:$JAVA_HOME"

RUN wget https://github.com/bazelbuild/bazel/releases/download/7.4.1/bazel-7.4.1-installer-linux-x86_64.sh
RUN sudo bash bazel-7.4.1-installer-linux-x86_64.sh

RUN git clone --depth 1 https://github.com/google/mediapipe.git

WORKDIR /home/$USER/mediapipe

ENV HOME=/home/$USER/mediapipe

# RUN pip3 config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple

RUN pip3 install -r requirements.txt

RUN bash setup_android_sdk_and_ndk.sh $HOME/Android/Sdk $HOME/Android/Sdk/ndk-bundle r26d --accept-licenses

ENV PATH="$PATH:$HOME/Android/Sdk/ndk-bundle/android-ndk-r26d/toolchains/llvm/prebuilt/linux-x86_64/bin"

ENV GLOG_logtostderr=1

RUN bazel build --cxxopt=-DABSL_FLAGS_STRIP_NAMES=0 -c opt --config=android_arm64 --define=xnn_enable_arm_i8mm=true mediapipe/tasks/cc/genai/inference/c:llm_inference_engine_cpu_main