#aliases
alias prettyjson="python -m json.tool | pygmentize -l javascript"
alias deploy_awx="bash -c \"make deploy\""

# custom functions
function fish_greeting
    cd awx-operator
    git checkout (git describe --tags --abbrev=0) &> /dev/null

    echo ""
    echo "Welcome to the AWX deployment container!"
    echo ""
    echo "Ensure that your kubeconfig file is either created first in ~/.kube or that you mapped a local config to ~/.kube/config when instantiating this container."
    echo ""
    echo "Type `bash -c 'make deploy'` or `deploy_awx` (a fish shell alias for the former command) to attempt to deploy the version of the AWX Operator currently checked out."
    echo ""
end