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
    uint256 private vote_duration;
    uint8 private quorum_size = 0;
    mapping(address => bool) private parties;
    uint8 private party_count;
    uint32 private proposal_count = 0;
    bool private locked = false;

    struct proposal {
        uint32 id;
        uint256 timestamp;
        address recipient;
        uint256 amount;
        mapping(address => bool) parties;
        uint8 votes;
    }

    mapping(uint32 => proposal) private proposals;

    event Proposal(uint32 id, address recipient, uint256 amount);
    event Passed(uint32 id, address recipient, uint256 amount);
    event Failed(uint32 id, address recipient, uint256 amount);

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

    modifier noReentry() {
        require(!locked, "Reentry is not allowed");
        locked = true;
        _;
        locked = false;
    }

    function addParty(address p) external onlyOwner verifyAddress(p) {
        parties[p] = true;
        party_count += 1;
    }

    function setQuorumSize(uint8 size) external onlyOwner {
        require(proposal_count == 1, "Active proposals");
        require(size <= party_count, "Invalid quorum size");
        quorum_size = size;
    }

    function setVoteDuration(uint256 duration) external onlyOwner {
        require(proposal_count == 1, "Active proposals");
        vote_duration = duration;
    }

    function proposeMint(address recipient_, uint256 amount_)
        external
        verifyAddress(recipient_)
        validParty(msg.sender)
    {
        require(quorum_size > 0, "No quorum specified");
        proposals[proposal_count].recipient = recipient_;
        proposals[proposal_count].amount = amount_;
        proposals[proposal_count].timestamp = block.timestamp;
        proposals[proposal_count].id = proposal_count;
        emit Proposal(proposal_count, recipient_, amount_);
        proposal_count += 1;
    }

    function gc(uint32 begin, uint32 end) external onlyOwner {
        uint256 now_ = block.timestamp;
        for (uint32 i = begin; i < end; ++i) {
            if (proposals[i].recipient == address(0)) {
                continue;
            }
            if (proposals[i].timestamp + vote_duration > now_) {
                continue;
            }
            emit Failed(i, proposals[i].recipient, proposals[i].amount);
            delete proposals[i];
        }
    }

    function vote(uint32 id) external validParty(msg.sender) noReentry {
        require(proposals[id].recipient != address(0), "Invalid proposal");
        require(!proposals[id].parties[msg.sender], "Already voted");
        proposals[id].parties[msg.sender] = true;
        proposals[id].votes += 1;

        if (proposals[id].votes >= quorum_size) {
            _mint(proposals[id].recipient, proposals[id].amount);
            emit Passed(id, proposals[id].recipient, proposals[id].amount);
            delete proposals[id];
        }
    }
}
