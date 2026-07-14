package com.example.rentalmanagement.room.repository;

import java.nio.charset.*;
import com.example.rentalmanagement.common.scheduling.*;

import java.math.*;
import java.time.*;
import java.util.*;
import java.io.*;
import javax.crypto.*;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import com.example.rentalmanagement.common.api.*;
import com.example.rentalmanagement.common.audit.*;
import com.example.rentalmanagement.common.enums.*;
import com.example.rentalmanagement.common.exception.*;
import com.example.rentalmanagement.common.security.*;
import com.example.rentalmanagement.auth.dto.*;
import com.example.rentalmanagement.auth.service.*;
import com.example.rentalmanagement.building.*;
import com.example.rentalmanagement.building.dto.*;
import com.example.rentalmanagement.building.repository.*;
import com.example.rentalmanagement.building.service.*;
import com.example.rentalmanagement.contract.*;
import com.example.rentalmanagement.contract.dto.*;
import com.example.rentalmanagement.contract.repository.*;
import com.example.rentalmanagement.contract.service.*;
import com.example.rentalmanagement.dashboard.dto.*;
import com.example.rentalmanagement.dashboard.service.*;
import com.example.rentalmanagement.invoice.*;
import com.example.rentalmanagement.invoice.dto.*;
import com.example.rentalmanagement.invoice.repository.*;
import com.example.rentalmanagement.invoice.service.*;
import com.example.rentalmanagement.maintenance.*;
import com.example.rentalmanagement.maintenance.dto.*;
import com.example.rentalmanagement.maintenance.repository.*;
import com.example.rentalmanagement.maintenance.service.*;
import com.example.rentalmanagement.meterreading.*;
import com.example.rentalmanagement.meterreading.dto.*;
import com.example.rentalmanagement.meterreading.repository.*;
import com.example.rentalmanagement.notification.*;
import com.example.rentalmanagement.notification.dto.*;
import com.example.rentalmanagement.notification.repository.*;
import com.example.rentalmanagement.notification.service.*;
import com.example.rentalmanagement.payment.*;
import com.example.rentalmanagement.payment.dto.*;
import com.example.rentalmanagement.payment.repository.*;
import com.example.rentalmanagement.room.*;
import com.example.rentalmanagement.room.dto.*;
import com.example.rentalmanagement.serviceitem.*;
import com.example.rentalmanagement.serviceitem.dto.*;
import com.example.rentalmanagement.serviceitem.repository.*;
import com.example.rentalmanagement.tenant.*;
import com.example.rentalmanagement.tenant.dto.*;
import com.example.rentalmanagement.tenant.repository.*;
import com.example.rentalmanagement.user.*;
import com.example.rentalmanagement.user.dto.*;
import com.example.rentalmanagement.user.repository.*;

public interface RoomRepository extends JpaRepository<Room, Long> {
    public boolean existsByBuildingIdAndRoomNumber(Long buildingId, String roomNumber);
    public boolean existsByBuildingIdAndRoomNumberIgnoreCase(Long buildingId, String roomNumber);
    public boolean existsByBuildingIdAndRoomNumberIgnoreCaseAndIdNot(Long buildingId, String roomNumber, Long id);

    @Query("""
            select r from Room r
            where r.isDeleted = false
              and (:status is null or r.status = :status)
              and (:buildingId is null or r.building.id = :buildingId)
              and (:floorId is null or r.floor.id = :floorId)
              and (:keyword is null
               or lower(r.roomNumber) like lower(concat('%', :keyword, '%'))
               or lower(r.building.name) like lower(concat('%', :keyword, '%'))
               or lower(r.building.code) like lower(concat('%', :keyword, '%'))
               or lower(r.floor.name) like lower(concat('%', :keyword, '%'))
               or str(r.floor.floorNumber) like concat('%', :keyword, '%'))
            """)
    public Page<Room> search(@Param("status") RoomStatus status, @Param("buildingId") Long buildingId, @Param("floorId") Long floorId, @Param("keyword") String keyword, Pageable pageable);

    public long countByStatusAndIsDeletedFalse(RoomStatus status);
    public long countByIsDeletedFalse();
}
