import assert from 'assert';

import { type DeployFunction } from 'hardhat-deploy/types';

const contractName = 'DeLayerBridged';

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre;

    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    assert(deployer, 'Missing named deployer account');
    assert(hre.network.config.chainId === 8453, 'This deployment script is only available for Base')

    console.log(`Network: ${hre.network.name}`);
    console.log(`Deployer: ${deployer}`);

    const endpointV2Deployment = await hre.deployments.get('EndpointV2');

    const { address } = await deploy(contractName, {
        from: deployer,
        args: [
            'De Layer', // name
            'DEAI', // symbol
            endpointV2Deployment.address, // LayerZero's EndpointV2 address
            '0x2512f9b888C76bE41E8Ed499a8C61dFe03DBf518', // delegate
            '0xD849882983F1bA8A3c23B16b65BB0173A7f63b63', // router
        ],
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`);
};

deploy.tags = [contractName, 'base'];

export default deploy;
