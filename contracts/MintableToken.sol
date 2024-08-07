/*
 * Copyright (c) 2024, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    int256 private vote_duration;
    int8 private quorum_size = 0;
    mapping(address => bool) private parties;
    int8 private party_count;

    int32 private proposal_count = 0;

    struct proposal {
        uint256 timestamp;
        address recipient;
        uint256 amount;
        mapping(address => bool) parties;
        int8 votes;
    }

    mapping(int32 => proposal) private proposals;

    constructor(address initialOwner)
        ERC20("MintableToken", "MT")
        Ownable(initialOwner)
    {
        parties[initialOwner] = true;
    }

    modifier verifyAddress(address a) {
        require(a != address(0), "Invalid address");
        _;
    } 

    modifier validParty(address a) {
        require(parties[a], "Invalid party");
        _;
    }

    function addParty(address p) external onlyOwner verifyAddress(p) {
        parties[p] = true;
        party_count += 1;
    }

    function setQuorumSize(int8 size) external onlyOwner {
        require(proposal_count == 1, "Active proposals");
        require(size <= party_count, "Invalid quorum size");
        quorum_size = size;
    }

    function setVoteDuration(int256 duration) external onlyOwner {
        require(proposal_count == 1, "Active proposals");
        vote_duration = duration;
    }

    function proposeMint(address recipient_, uint256 amount_) external verifyAddress(recipient_) validParty(msg.sender) {
        require(quorum_size > 0, "No quorum specified");
        proposals[proposal_count].recipient = recipient_;
        proposals[proposal_count].amount = amount_;
        proposals[proposal_count].timestamp = block.timestamp;
        proposal_count += 1;
    }

    function gc(int32 begin, int32 end) external onlyOwner {

    }

    function vote(int32 id) external validParty(msg.sender) {
        require(proposals[id].recipient != address(0), "Invalid proposal");
        require(!proposals[id].parties[msg.sender], "Already voted");
        proposals[id].parties[msg.sender] = true;
        proposals[id].votes += 1;

        if (proposals[id].votes >= quorum_size) {
            _mint(proposals[id].recipient, proposals[id].amount);
            delete proposals[id];
        }
    }

    function pendingProposals() external view returns (mapping(int32 => proposal) memory) {
        return proposals;
    }
 }
