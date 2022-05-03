pragma ton-solidity >= 0.57.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./PlatformType.sol";

import "@broxus/contracts/contracts/platform/Platform.sol";


abstract contract PlatformUtils {

    TvmCell public _platformCode;

    function _auctionAddress(address root, uint64 nonce) internal view returns (address) {
        TvmCell stateInit = _buildAuctionStateInit(root, nonce);
        return calcAddress(stateInit);
    }

    function _deAuctionAddress(address root, uint64 nonce) internal view returns (address) {
        TvmCell stateInit = _buildDeAuctionStateInit(root, nonce);
        return calcAddress(stateInit);
    }

    function _deParticipantAddress(address root, address owner) internal view returns (address) {
        TvmCell stateInit = _buildDeParticipantStateInit(root, owner);
        return calcAddress(stateInit);
    }

    function _buildAuctionStateInit(address root, uint64 nonce) internal view returns (TvmCell) {
        TvmCell initialData = abi.encode(nonce);
        return _buildPlatformStateInit(root, PlatformType.AUCTION, initialData);
    }

    function _buildDeAuctionStateInit(address root, uint64 nonce) internal view returns (TvmCell) {
        TvmCell initialData = abi.encode(nonce);
        return _buildPlatformStateInit(root, PlatformType.DE_AUCTION, initialData);
    }

    function _buildDeParticipantStateInit(address root, address owner) internal view returns (TvmCell) {
        TvmCell initialData = abi.encode(owner);
        return _buildPlatformStateInit(root, PlatformType.DE_PARTICIPANT, initialData);
    }

    function _buildPlatformStateInit(address root, PlatformType platformType, TvmCell initialData) private view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Platform,
            varInit: {
                root: root,
                platformType: uint8(platformType),
                initialData: initialData,
                platformCode: _platformCode
            },
            pubkey: 0,
            code: _platformCode
        });
    }

   function calcAddress(TvmCell stateInit) public pure returns (address) {
       return address(tvm.hash(stateInit));
   }

}
