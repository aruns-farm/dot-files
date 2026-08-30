# [ported from .zshrc]
function bwunlock --description 'Unlock Bitwarden and export session key'
    set -gx BW_SESSION (bw unlock --raw)
    echo "✓ Bitwarden unlocked"
end
