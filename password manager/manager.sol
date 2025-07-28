// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SimplePasswordManager
 * @dev A basic password manager smart contract with 3 core functions
 */
contract SimplePasswordManager {
    
    // Structure to store password data
    struct Password {
        string website;
        string encryptedData; // Contains encrypted username:password
        uint256 timestamp;
    }
    
    // Mapping: user address => password ID => Password
    mapping(address => mapping(uint256 => Password)) private passwords;
    
    // Mapping: user address => total password count
    mapping(address => uint256) private passwordCounts;
    
    // Events
    event PasswordStored(address indexed user, uint256 passwordId, string website);
    event PasswordRetrieved(address indexed user, uint256 passwordId);
    event PasswordGenerated(address indexed user, string generatedPassword);
    
    /**
     * @dev Function 1: Store encrypted password securely
     * @param website The website/service name
     * @param encryptedData Encrypted username and password (encrypted client-side)
     */
    function storePassword(string memory website, string memory encryptedData) external {
        require(bytes(website).length > 0, "Website name cannot be empty");
        require(bytes(encryptedData).length > 0, "Encrypted data cannot be empty");
        
        uint256 passwordId = passwordCounts[msg.sender] + 1;
        
        passwords[msg.sender][passwordId] = Password({
            website: website,
            encryptedData: encryptedData,
            timestamp: block.timestamp
        });
        
        passwordCounts[msg.sender] = passwordId;
        
        emit PasswordStored(msg.sender, passwordId, website);
    }
    
    /**
     * @dev Function 2: Retrieve stored password by ID
     * @param passwordId The ID of the password to retrieve
     * @return website The website name
     * @return encryptedData The encrypted password data
     * @return timestamp When the password was stored
     */
    function getPassword(uint256 passwordId) external returns (string memory website, string memory encryptedData, uint256 timestamp) {
        require(passwordId > 0 && passwordId <= passwordCounts[msg.sender], "Invalid password ID");
        
        Password memory pwd = passwords[msg.sender][passwordId];
        
        emit PasswordRetrieved(msg.sender, passwordId);
        
        return (pwd.website, pwd.encryptedData, pwd.timestamp);
    }
    
    /**
     * @dev Function 3: Generate a strong random password
     * @param length The desired length of password (8-32 characters)
     * @return generatedPassword A strong random password
     */
    function generateStrongPassword(uint256 length) external returns (string memory generatedPassword) {
        require(length >= 8 && length <= 32, "Password length must be between 8 and 32");
        
        // Character sets
        string memory chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*";
        bytes memory charBytes = bytes(chars);
        bytes memory password = new bytes(length);
        
        // Generate pseudo-random password using blockchain data
        // Fixed: Using block.prevrandao instead of deprecated block.difficulty
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,  // Fixed: replaced block.difficulty with block.prevrandao
            msg.sender,
            block.number
        )));
        
        for (uint256 i = 0; i < length; i++) {
            randomSeed = uint256(keccak256(abi.encodePacked(randomSeed, i)));
            password[i] = charBytes[randomSeed % charBytes.length];
        }
        
        generatedPassword = string(password);
        
        emit PasswordGenerated(msg.sender, generatedPassword);
        
        return generatedPassword;
    }
    
    /**
     * @dev Delete a stored password
     * @param passwordId The ID of the password to delete
     */
    function deletePassword(uint256 passwordId) external {
        require(passwordId > 0 && passwordId <= passwordCounts[msg.sender], "Invalid password ID");
        
        delete passwords[msg.sender][passwordId];
        
        emit PasswordDeleted(msg.sender, passwordId);
    }
    
    /**
     * @dev Update an existing password
     * @param passwordId The ID of the password to update
     * @param website The new website/service name
     * @param encryptedData New encrypted username and password
     */
    function updatePassword(uint256 passwordId, string memory website, string memory encryptedData) external {
        require(passwordId > 0 && passwordId <= passwordCounts[msg.sender], "Invalid password ID");
        require(bytes(website).length > 0, "Website name cannot be empty");
        require(bytes(encryptedData).length > 0, "Encrypted data cannot be empty");
        
        passwords[msg.sender][passwordId] = Password({
            website: website,
            encryptedData: encryptedData,
            timestamp: block.timestamp
        });
        
        emit PasswordUpdated(msg.sender, passwordId, website);
    }
    
    // Additional helper functions
    
    /**
     * @dev Get total number of passwords stored by user
     * @return count Total password count
     */
    function getPasswordCount() external view returns (uint256 count) {
        return passwordCounts[msg.sender];
    }
    
    /**
     * @dev Get all password IDs and websites for user
     * @return websites Array of website names
     * @return timestamps Array of storage timestamps
     */
    function getAllPasswords() external view returns (string[] memory websites, uint256[] memory timestamps) {
        uint256 count = passwordCounts[msg.sender];
        websites = new string[](count);
        timestamps = new uint256[](count);
        
        for (uint256 i = 1; i <= count; i++) {
            websites[i-1] = passwords[msg.sender][i].website;
            timestamps[i-1] = passwords[msg.sender][i].timestamp;
        }
        
        return (websites, timestamps);
    }
    
    // Additional events for new functions
    event PasswordDeleted(address indexed user, uint256 passwordId);
    event PasswordUpdated(address indexed user, uint256 passwordId, string website);
}
