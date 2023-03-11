// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract GNaira is ERC20, Ownable {
    constructor() ERC20("gNGN", "gNGN") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function blackList(address _address) public onlyOwner {
        _blacklist[_address] = true;
    }

    function unBlackList(address _address) public onlyOwner {
        _blacklist[_address] = false;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(!_blacklist[msg.sender], "Sender is blacklisted");
        require(!_blacklist[to], "Recipient is blacklisted");
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(!_blacklist[from], "Sender is blacklisted");
        require(!_blacklist[to], "Recipient is blacklisted");
        return super.transferFrom(from, to, value);
    }

    mapping(address => bool) private _blacklist;
}



contract GNGNToken is ERC20, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    EnumerableSet.AddressSet private _minters;

    constructor() ERC20("gNGN", "gNGN") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GOVERNOR_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "GNGN: must have MINTER_ROLE to mint");
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "GNGN: must have MINTER_ROLE to burn");
        _burn(msg.sender, amount);
    }

    function blacklist(address account) public onlyRole(GOVERNOR_ROLE) {
        _blacklist[account] = true;
        emit Blacklist(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function addMinter(address account) public onlyRole(GOVERNOR_ROLE) {
        require(!_minters.contains(account), "GNGN: account is already a minter");
        _minters.add(account);
        grantRole(MINTER_ROLE, account);
    }

    function removeMinter(address account) public onlyRole(GOVERNOR_ROLE) {
        require(_minters.contains(account), "GNGN: account is not a minter");
        _minters.remove(account);
        revokeRole(MINTER_ROLE, account);
    }

    function getMinters() public view returns (address[] memory) {
        uint256 length = _minters.length();
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = _minters.at(i);
        }
        return result;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!isBlacklisted(from), "GNGN: sender is blacklisted");
        require(!isBlacklisted(to), "GNGN: recipient is blacklisted");
        super._beforeTokenTransfer(from, to, amount);
    }

    mapping(address => bool) private _blacklist;

    event Blacklist(address indexed account);
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
}
