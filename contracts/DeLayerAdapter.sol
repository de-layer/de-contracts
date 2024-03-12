//
//     ___         __
//    /   \___    / /  __ _ _   _  ___ _ __
//   / /\ / _ \  / /  / _` | | | |/ _ \ '__|
//  / /_//  __/ / /__| (_| | |_| |  __/ |
// /___,' \___| \____/\__,_|\__, |\___|_|
//                          |___/
//
//    Website: https://delayer.network/
//
//    Telegram: https://t.me/delayerevm
//    Twitter: https://twitter.com/delayerevm
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OFTAdapter } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract DeLayerAdapter is OFTAdapter {
    constructor(
        address _token,
        address _layerZeroEndpoint,
        address _owner
    ) OFTAdapter(_token, _layerZeroEndpoint, _owner) Ownable(_owner) {}
}
