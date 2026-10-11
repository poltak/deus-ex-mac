export GHIDRA_INSTALL_DIR=$HOME/tools/ghidra_12.1.4_PUBLIC
export JAVA_HOME=$HOME/.local/share/mise/installs/java/temurin-21.0.12+101.0.LTS
export PATH=$JAVA_HOME/bin:$PATH
export REA_ANALYSIS_PROVIDER=ghidra
export REA_GHIDRA_STARTUP_TIMEOUT_MS=1800000
alias rea="node $HOME/src/rea/scripts/rea.mjs"
rea() { node $HOME/src/rea/scripts/rea.mjs "$@"; }
