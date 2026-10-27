import Foundation
import SQLite3

public final class DatabaseManager {
    public static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbLock = NSLock()
    
    private init() {
        openDatabase()
        createTables()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func getDatabasePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as NSString
        return documentsDirectory.appendingPathComponent("optical_lab.sqlite")
    }
    
    private func openDatabase() {
        let path = getDatabasePath()
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Error opening SQLite database at \(path)")
        }
    }
    
    private func createTables() {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let createLensesTable = """
        CREATE TABLE IF NOT EXISTS lenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode TEXT UNIQUE NOT NULL,
            sku TEXT,
            brand TEXT NOT NULL,
            lens_type TEXT NOT NULL,
            material TEXT NOT NULL,
            coating TEXT,
            sphere REAL NOT NULL,
            cylinder REAL NOT NULL,
            add_power REAL DEFAULT 0.0,
            diameter INTEGER DEFAULT 70,
            quantity_on_hand INTEGER DEFAULT 0,
            min_threshold INTEGER DEFAULT 2,
            bin_location TEXT,
            unit_cost REAL DEFAULT 0.0,
            updated_at INTEGER NOT NULL
        );
        """
        
        let createJobsTable = """
        CREATE TABLE IF NOT EXISTS jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tray_number TEXT UNIQUE NOT NULL,
            order_number TEXT,
            patient_name TEXT,
            customer_name TEXT,
            doctor_name TEXT,
            stage TEXT NOT NULL DEFAULT 'NEW_ORDER',
            priority TEXT DEFAULT 'Normal',
            frame_model TEXT,
            frame_type TEXT DEFAULT 'PLASTIC_ZYL',
            edger_machine TEXT,
            od_sphere REAL DEFAULT 0.0,
            od_cylinder REAL DEFAULT 0.0,
            od_axis INTEGER DEFAULT 0,
            od_add REAL DEFAULT 0.0,
            od_pd REAL DEFAULT 31.0,
            od_seg_height REAL DEFAULT 0.0,
            od_lens_barcode TEXT,
            os_sphere REAL DEFAULT 0.0,
            os_cylinder REAL DEFAULT 0.0,
            os_axis INTEGER DEFAULT 0,
            os_add REAL DEFAULT 0.0,
            os_pd REAL DEFAULT 31.0,
            os_seg_height REAL DEFAULT 0.0,
            os_lens_barcode TEXT,
            notes TEXT,
            is_archived INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            completed_at INTEGER
        );
        """
        
        let createQcTable = """
        CREATE TABLE IF NOT EXISTS qc_inspections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_id INTEGER NOT NULL,
            tray_number TEXT NOT NULL,
            inspector_name TEXT,
            inspection_date INTEGER NOT NULL,
            od_sph_ok INTEGER DEFAULT 0,
            od_cyl_ok INTEGER DEFAULT 0,
            od_axis_ok INTEGER DEFAULT 0,
            os_sph_ok INTEGER DEFAULT 0,
            os_cyl_ok INTEGER DEFAULT 0,
            os_axis_ok INTEGER DEFAULT 0,
            pd_aligned INTEGER DEFAULT 0,
            cosmetic_passed INTEGER DEFAULT 0,
            bevel_fit_passed INTEGER DEFAULT 0,
            passed INTEGER DEFAULT 0,
            notes TEXT
        );
        """
        
        execute(sql: createLensesTable)
        execute(sql: createJobsTable)
        execute(sql: createQcTable)
        // Migration safety check
        execute(sql: "ALTER TABLE jobs ADD COLUMN is_archived INTEGER DEFAULT 0;")
    }
    
    private func execute(sql: String) {
        var errMsg: UnsafeMutablePointer<Int8>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            if let err = errMsg {
                let msg = String(cString: err)
                print("SQLite Exec Error: \(msg)")
                sqlite3_free(errMsg)
            }
        }
    }
    
    // MARK: - Lens Inventory Operations
    
    public func getAllLenses() -> [LensItem] {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        var list: [LensItem] = []
        let sql = "SELECT id, barcode, sku, brand, lens_type, material, coating, sphere, cylinder, add_power, diameter, quantity_on_hand, min_threshold, bin_location, unit_cost, updated_at FROM lenses ORDER BY brand, sphere, cylinder ASC;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                list.append(parseLensRow(stmt))
            }
        }
        sqlite3_finalize(stmt)
        return list
    }
    
    public func getLens(byBarcode barcode: String) -> LensItem? {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = "SELECT id, barcode, sku, brand, lens_type, material, coating, sphere, cylinder, add_power, diameter, quantity_on_hand, min_threshold, bin_location, unit_cost, updated_at FROM lenses WHERE barcode = ? LIMIT 1;"
        var stmt: OpaquePointer?
        var item: LensItem?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (barcode as NSString).utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_ROW {
                item = parseLensRow(stmt)
            }
        }
        sqlite3_finalize(stmt)
        return item
    }
    
    public func getLens(byId id: Int64) -> LensItem? {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = "SELECT id, barcode, sku, brand, lens_type, material, coating, sphere, cylinder, add_power, diameter, quantity_on_hand, min_threshold, bin_location, unit_cost, updated_at FROM lenses WHERE id = ? LIMIT 1;"
        var stmt: OpaquePointer?
        var item: LensItem?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_ROW {
                item = parseLensRow(stmt)
            }
        }
        sqlite3_finalize(stmt)
        return item
    }
    
    public func insertLens(_ lens: LensItem) -> Int64 {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = """
        INSERT OR REPLACE INTO lenses (barcode, sku, brand, lens_type, material, coating, sphere, cylinder, add_power, diameter, quantity_on_hand, min_threshold, bin_location, unit_cost, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        var rowId: Int64 = -1
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (lens.barcode as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (lens.sku as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (lens.brand as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (lens.lensType.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (lens.material.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (lens.coating as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 7, lens.sphere)
            sqlite3_bind_double(stmt, 8, lens.cylinder)
            sqlite3_bind_double(stmt, 9, lens.addPower)
            sqlite3_bind_int(stmt, 10, Int32(lens.diameter))
            sqlite3_bind_int(stmt, 11, Int32(lens.quantityOnHand))
            sqlite3_bind_int(stmt, 12, Int32(lens.minThreshold))
            sqlite3_bind_text(stmt, 13, (lens.binLocation as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 14, lens.unitCost)
            sqlite3_bind_int64(stmt, 15, Int64(lens.updatedAt.timeIntervalSince1970 * 1000))
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                rowId = sqlite3_last_insert_rowid(db)
            }
        }
        sqlite3_finalize(stmt)
        return rowId
    }
    
    public func updateLens(_ lens: LensItem) -> Bool {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = """
        UPDATE lenses SET sku = ?, brand = ?, lens_type = ?, material = ?, coating = ?, sphere = ?, cylinder = ?, add_power = ?, diameter = ?, quantity_on_hand = ?, min_threshold = ?, bin_location = ?, unit_cost = ?, updated_at = ?
        WHERE barcode = ?;
        """
        var stmt: OpaquePointer?
        var success = false
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (lens.sku as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (lens.brand as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (lens.lensType.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (lens.material.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (lens.coating as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 6, lens.sphere)
            sqlite3_bind_double(stmt, 7, lens.cylinder)
            sqlite3_bind_double(stmt, 8, lens.addPower)
            sqlite3_bind_int(stmt, 9, Int32(lens.diameter))
            sqlite3_bind_int(stmt, 10, Int32(lens.quantityOnHand))
            sqlite3_bind_int(stmt, 11, Int32(lens.minThreshold))
            sqlite3_bind_text(stmt, 12, (lens.binLocation as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 13, lens.unitCost)
            sqlite3_bind_int64(stmt, 14, Int64(Date().timeIntervalSince1970 * 1000))
            sqlite3_bind_text(stmt, 15, (lens.barcode as NSString).utf8String, -1, nil)
            
            success = (sqlite3_step(stmt) == SQLITE_DONE)
        }
        sqlite3_finalize(stmt)
        return success
    }
    
    public func adjustLensStock(barcode: String, delta: Int) -> Bool {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = "UPDATE lenses SET quantity_on_hand = MAX(0, quantity_on_hand + ?), updated_at = ? WHERE barcode = ?;"
        var stmt: OpaquePointer?
        var success = false
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(delta))
            sqlite3_bind_int64(stmt, 2, Int64(Date().timeIntervalSince1970 * 1000))
            sqlite3_bind_text(stmt, 3, (barcode as NSString).utf8String, -1, nil)
            success = (sqlite3_step(stmt) == SQLITE_DONE)
        }
        sqlite3_finalize(stmt)
        return success
    }
    
    public func deleteLens(id: Int64) -> Bool {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = "DELETE FROM lenses WHERE id = ?;"
        var stmt: OpaquePointer?
        var success = false
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            success = (sqlite3_step(stmt) == SQLITE_DONE)
        }
        sqlite3_finalize(stmt)
        return success
    }
    
    // MARK: - Job Pipeline Operations
    
    public func getAllJobs() -> [OpticalJob] {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        var list: [OpticalJob] = []
        let sql = "SELECT id, tray_number, order_number, patient_name, customer_name, doctor_name, stage, priority, frame_model, frame_type, edger_machine, od_sphere, od_cylinder, od_axis, od_add, od_pd, od_seg_height, od_lens_barcode, os_sphere, os_cylinder, os_axis, os_add, os_pd, os_seg_height, os_lens_barcode, notes, is_archived, created_at, updated_at, completed_at FROM jobs WHERE is_archived = 0 ORDER BY updated_at DESC;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                list.append(parseJobRow(stmt))
            }
        }
        sqlite3_finalize(stmt)
        return list
    }

    public func getArchivedJobs() -> [OpticalJob] {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        var list: [OpticalJob] = []
        let sql = "SELECT id, tray_number, order_number, patient_name, customer_name, doctor_name, stage, priority, frame_model, frame_type, edger_machine, od_sphere, od_cylinder, od_axis, od_add, od_pd, od_seg_height, od_lens_barcode, os_sphere, os_cylinder, os_axis, os_add, os_pd, os_seg_height, os_lens_barcode, notes, is_archived, created_at, updated_at, completed_at FROM jobs WHERE is_archived = 1 ORDER BY updated_at DESC;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                list.append(parseJobRow(stmt))
            }
        }
        sqlite3_finalize(stmt)
        return list
    }
    
    public func getJob(byId id: Int64) -> OpticalJob? {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = "SELECT id, tray_number, order_number, patient_name, customer_name, doctor_name, stage, priority, frame_model, frame_type, edger_machine, od_sphere, od_cylinder, od_axis, od_add, od_pd, od_seg_height, od_lens_barcode, os_sphere, os_cylinder, os_axis, os_add, os_pd, os_seg_height, os_lens_barcode, notes, is_archived, created_at, updated_at, completed_at FROM jobs WHERE id = ? LIMIT 1;"
        var stmt: OpaquePointer?
        var job: OpticalJob?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_ROW {
                job = parseJobRow(stmt)
            }
        }
        sqlite3_finalize(stmt)
        return job
    }
    
    public func getJob(byTrayNumber trayNumber: String) -> OpticalJob? {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = "SELECT id, tray_number, order_number, patient_name, customer_name, doctor_name, stage, priority, frame_model, frame_type, edger_machine, od_sphere, od_cylinder, od_axis, od_add, od_pd, od_seg_height, od_lens_barcode, os_sphere, os_cylinder, os_axis, os_add, os_pd, os_seg_height, os_lens_barcode, notes, is_archived, created_at, updated_at, completed_at FROM jobs WHERE tray_number = ? LIMIT 1;"
        var stmt: OpaquePointer?
        var job: OpticalJob?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (trayNumber as NSString).utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_ROW {
                job = parseJobRow(stmt)
            }
        }
        sqlite3_finalize(stmt)
        return job
    }
    
    public func insertJob(_ job: OpticalJob) -> Int64 {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = """
        INSERT OR REPLACE INTO jobs (tray_number, order_number, patient_name, customer_name, doctor_name, stage, priority, frame_model, frame_type, edger_machine, od_sphere, od_cylinder, od_axis, od_add, od_pd, od_seg_height, od_lens_barcode, os_sphere, os_cylinder, os_axis, os_add, os_pd, os_seg_height, os_lens_barcode, notes, created_at, updated_at, completed_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        var rowId: Int64 = -1
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (job.trayNumber as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (job.orderNumber as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (job.patientName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (job.customerName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (job.doctorName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (job.stage.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 7, (job.priority as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 8, (job.frameModel as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 9, (job.frameType.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 10, (job.edgerMachine as NSString).utf8String, -1, nil)
            
            sqlite3_bind_double(stmt, 11, job.odSphere)
            sqlite3_bind_double(stmt, 12, job.odCylinder)
            sqlite3_bind_int(stmt, 13, Int32(job.odAxis))
            sqlite3_bind_double(stmt, 14, job.odAdd)
            sqlite3_bind_double(stmt, 15, job.odPd)
            sqlite3_bind_double(stmt, 16, job.odSegHeight)
            sqlite3_bind_text(stmt, 17, (job.odLensBarcode as NSString).utf8String, -1, nil)
            
            sqlite3_bind_double(stmt, 18, job.osSphere)
            sqlite3_bind_double(stmt, 19, job.osCylinder)
            sqlite3_bind_int(stmt, 20, Int32(job.osAxis))
            sqlite3_bind_double(stmt, 21, job.osAdd)
            sqlite3_bind_double(stmt, 22, job.osPd)
            sqlite3_bind_double(stmt, 23, job.osSegHeight)
            sqlite3_bind_text(stmt, 24, (job.osLensBarcode as NSString).utf8String, -1, nil)
            
            sqlite3_bind_text(stmt, 25, (job.notes as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 26, Int64(job.createdAt.timeIntervalSince1970 * 1000))
            sqlite3_bind_int64(stmt, 27, Int64(job.updatedAt.timeIntervalSince1970 * 1000))
            
            if let completed = job.completedAt {
                sqlite3_bind_int64(stmt, 28, Int64(completed.timeIntervalSince1970 * 1000))
            } else {
                sqlite3_bind_null(stmt, 28)
            }
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                rowId = sqlite3_last_insert_rowid(db)
            }
        }
        sqlite3_finalize(stmt)
        return rowId
    }
    
    public func updateJob(_ job: OpticalJob) -> Bool {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = """
        UPDATE jobs SET order_number = ?, patient_name = ?, customer_name = ?, doctor_name = ?, stage = ?, priority = ?, frame_model = ?, frame_type = ?, edger_machine = ?, od_sphere = ?, od_cylinder = ?, od_axis = ?, od_add = ?, od_pd = ?, od_seg_height = ?, od_lens_barcode = ?, os_sphere = ?, os_cylinder = ?, os_axis = ?, os_add = ?, os_pd = ?, os_seg_height = ?, os_lens_barcode = ?, notes = ?, updated_at = ?, completed_at = ?
        WHERE tray_number = ?;
        """
        var stmt: OpaquePointer?
        var success = false
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (job.orderNumber as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (job.patientName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (job.customerName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (job.doctorName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (job.stage.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (job.priority as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 7, (job.frameModel as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 8, (job.frameType.rawValue as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 9, (job.edgerMachine as NSString).utf8String, -1, nil)
            
            sqlite3_bind_double(stmt, 10, job.odSphere)
            sqlite3_bind_double(stmt, 11, job.odCylinder)
            sqlite3_bind_int(stmt, 12, Int32(job.odAxis))
            sqlite3_bind_double(stmt, 13, job.odAdd)
            sqlite3_bind_double(stmt, 14, job.odPd)
            sqlite3_bind_double(stmt, 15, job.odSegHeight)
            sqlite3_bind_text(stmt, 16, (job.odLensBarcode as NSString).utf8String, -1, nil)
            
            sqlite3_bind_double(stmt, 17, job.osSphere)
            sqlite3_bind_double(stmt, 18, job.osCylinder)
            sqlite3_bind_int(stmt, 19, Int32(job.osAxis))
            sqlite3_bind_double(stmt, 20, job.osAdd)
            sqlite3_bind_double(stmt, 21, job.osPd)
            sqlite3_bind_double(stmt, 22, job.osSegHeight)
            sqlite3_bind_text(stmt, 23, (job.osLensBarcode as NSString).utf8String, -1, nil)
            
            sqlite3_bind_text(stmt, 24, (job.notes as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 25, Int64(Date().timeIntervalSince1970 * 1000))
            
            if let completed = job.completedAt {
                sqlite3_bind_int64(stmt, 26, Int64(completed.timeIntervalSince1970 * 1000))
            } else {
                sqlite3_bind_null(stmt, 26)
            }
            sqlite3_bind_text(stmt, 27, (job.trayNumber as NSString).utf8String, -1, nil)
            
            success = (sqlite3_step(stmt) == SQLITE_DONE)
        }
        sqlite3_finalize(stmt)
        return success
    }
    
    public func advanceJobStage(jobId: Int64) -> JobStage? {
        guard let job = getJob(byId: jobId) else { return nil }
        let nextStage = job.stage.next()
        var updatedJob = job
        updatedJob.stage = nextStage
        if nextStage == .completed && updatedJob.completedAt == nil {
            updatedJob.completedAt = Date()
        }
        if updateJob(updatedJob) {
            return nextStage
        }
        return nil
    }
    
    public func allocateLens(jobId: Int64, eye: String, lensBarcode: String) -> Bool {
        guard var job = getJob(byId: jobId) else { return false }
        if eye.uppercased() == "OD" {
            job.odLensBarcode = lensBarcode
        } else {
            job.osLensBarcode = lensBarcode
        }
        // If both lenses are allocated or at least one is allocated, update stage to STOCK_ALLOCATED if was NEW_ORDER
        if job.stage == .newOrder {
            job.stage = .stockAllocated
        }
        let updated = updateJob(job)
        if updated {
            // Automatically deduct 1 from lens stock
            _ = adjustLensStock(barcode: lensBarcode, delta: -1)
        }
        return updated
    }
    
    public func deleteJob(id: Int64) -> Bool {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = "DELETE FROM jobs WHERE id = ?;"
        var stmt: OpaquePointer?
        var success = false
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            success = (sqlite3_step(stmt) == SQLITE_DONE)
        }
        sqlite3_finalize(stmt)
        return success
    }
    
    // MARK: - QC Inspections
    
    public func insertQcInspection(_ qc: QcInspection) -> Int64 {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        let sql = """
        INSERT INTO qc_inspections (job_id, tray_number, inspector_name, inspection_date, od_sph_ok, od_cyl_ok, od_axis_ok, os_sph_ok, os_cyl_ok, os_axis_ok, pd_aligned, cosmetic_passed, bevel_fit_passed, passed, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        var rowId: Int64 = -1
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, qc.jobId)
            sqlite3_bind_text(stmt, 2, (qc.trayNumber as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (qc.inspectorName as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 4, Int64(qc.inspectionDate.timeIntervalSince1970 * 1000))
            sqlite3_bind_int(stmt, 5, qc.odSphOk ? 1 : 0)
            sqlite3_bind_int(stmt, 6, qc.odCylOk ? 1 : 0)
            sqlite3_bind_int(stmt, 7, qc.odAxisOk ? 1 : 0)
            sqlite3_bind_int(stmt, 8, qc.osSphOk ? 1 : 0)
            sqlite3_bind_int(stmt, 9, qc.osCylOk ? 1 : 0)
            sqlite3_bind_int(stmt, 10, qc.osAxisOk ? 1 : 0)
            sqlite3_bind_int(stmt, 11, qc.pdAligned ? 1 : 0)
            sqlite3_bind_int(stmt, 12, qc.cosmeticPassed ? 1 : 0)
            sqlite3_bind_int(stmt, 13, qc.bevelFitPassed ? 1 : 0)
            sqlite3_bind_int(stmt, 14, qc.passed ? 1 : 0)
            sqlite3_bind_text(stmt, 15, (qc.notes as NSString).utf8String, -1, nil)
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                rowId = sqlite3_last_insert_rowid(db)
            }
        }
        sqlite3_finalize(stmt)
        return rowId
    }
    
    public func getQcInspections() -> [QcInspection] {
        dbLock.lock()
        defer { dbLock.unlock() }
        
        var list: [QcInspection] = []
        let sql = "SELECT id, job_id, tray_number, inspector_name, inspection_date, od_sph_ok, od_cyl_ok, od_axis_ok, os_sph_ok, os_cyl_ok, os_axis_ok, pd_aligned, cosmetic_passed, bevel_fit_passed, passed, notes FROM qc_inspections ORDER BY inspection_date DESC;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = sqlite3_column_int64(stmt, 0)
                let jobId = sqlite3_column_int64(stmt, 1)
                let tray = String(cString: sqlite3_column_text(stmt, 2))
                let inspector = sqlite3_column_text(stmt, 3) != nil ? String(cString: sqlite3_column_text(stmt, 3)) : ""
                let date = Date(timeIntervalSince1970: Double(sqlite3_column_int64(stmt, 4)) / 1000.0)
                let odSph = sqlite3_column_int(stmt, 5) == 1
                let odCyl = sqlite3_column_int(stmt, 6) == 1
                let odAxis = sqlite3_column_int(stmt, 7) == 1
                let osSph = sqlite3_column_int(stmt, 8) == 1
                let osCyl = sqlite3_column_int(stmt, 9) == 1
                let osAxis = sqlite3_column_int(stmt, 10) == 1
                let pd = sqlite3_column_int(stmt, 11) == 1
                let cosmetic = sqlite3_column_int(stmt, 12) == 1
                let bevel = sqlite3_column_int(stmt, 13) == 1
                let passed = sqlite3_column_int(stmt, 14) == 1
                let notes = sqlite3_column_text(stmt, 15) != nil ? String(cString: sqlite3_column_text(stmt, 15)) : ""
                
                list.append(QcInspection(id: id, jobId: jobId, trayNumber: tray, inspectorName: inspector, inspectionDate: date, odSphOk: odSph, odCylOk: odCyl, odAxisOk: odAxis, osSphOk: osSph, osCylOk: osCyl, osAxisOk: osAxis, pdAligned: pd, cosmeticPassed: cosmetic, bevelFitPassed: bevel, passed: passed, notes: notes))
            }
        }
        sqlite3_finalize(stmt)
        return list
    }
    
    // MARK: - Row Parsing Helpers
    
    private func parseLensRow(_ stmt: OpaquePointer?) -> LensItem {
        let id = sqlite3_column_int64(stmt, 0)
        let barcode = String(cString: sqlite3_column_text(stmt, 1))
        let sku = sqlite3_column_text(stmt, 2) != nil ? String(cString: sqlite3_column_text(stmt, 2)) : ""
        let brand = String(cString: sqlite3_column_text(stmt, 3))
        let typeStr = String(cString: sqlite3_column_text(stmt, 4))
        let matStr = String(cString: sqlite3_column_text(stmt, 5))
        let coating = sqlite3_column_text(stmt, 6) != nil ? String(cString: sqlite3_column_text(stmt, 6)) : ""
        let sphere = sqlite3_column_double(stmt, 7)
        let cylinder = sqlite3_column_double(stmt, 8)
        let add = sqlite3_column_double(stmt, 9)
        let diameter = Int(sqlite3_column_int(stmt, 10))
        let qty = Int(sqlite3_column_int(stmt, 11))
        let minThresh = Int(sqlite3_column_int(stmt, 12))
        let bin = sqlite3_column_text(stmt, 13) != nil ? String(cString: sqlite3_column_text(stmt, 13)) : ""
        let cost = sqlite3_column_double(stmt, 14)
        let updatedAt = Date(timeIntervalSince1970: Double(sqlite3_column_int64(stmt, 15)) / 1000.0)
        
        let lensType = LensType(rawValue: typeStr) ?? .singleVision
        let material = LensMaterial(rawValue: matStr) ?? .cr39
        
        return LensItem(id: id, barcode: barcode, sku: sku, brand: brand, lensType: lensType, material: material, coating: coating, sphere: sphere, cylinder: cylinder, addPower: add, diameter: diameter, quantityOnHand: qty, minThreshold: minThresh, binLocation: bin, unitCost: cost, updatedAt: updatedAt)
    }
    
    public func archiveJob(id: Int64) -> Bool {
        dbLock.lock()
        defer { dbLock.unlock() }
        let sql = "UPDATE jobs SET is_archived = 1, updated_at = ? WHERE id = ?;"
        var stmt: OpaquePointer?
        var success = false
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, Int64(Date().timeIntervalSince1970 * 1000))
            sqlite3_bind_int64(stmt, 2, id)
            success = sqlite3_step(stmt) == SQLITE_DONE
        }
        sqlite3_finalize(stmt)
        return success
    }

    public func unarchiveJob(id: Int64) -> Bool {
        dbLock.lock()
        defer { dbLock.unlock() }
        let sql = "UPDATE jobs SET is_archived = 0, updated_at = ? WHERE id = ?;"
        var stmt: OpaquePointer?
        var success = false
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, Int64(Date().timeIntervalSince1970 * 1000))
            sqlite3_bind_int64(stmt, 2, id)
            success = sqlite3_step(stmt) == SQLITE_DONE
        }
        sqlite3_finalize(stmt)
        return success
    }

    private func parseJobRow(_ stmt: OpaquePointer?) -> OpticalJob {
        let id = sqlite3_column_int64(stmt, 0)
        let tray = String(cString: sqlite3_column_text(stmt, 1))
        let order = sqlite3_column_text(stmt, 2) != nil ? String(cString: sqlite3_column_text(stmt, 2)) : ""
        let patient = sqlite3_column_text(stmt, 3) != nil ? String(cString: sqlite3_column_text(stmt, 3)) : ""
        let customer = sqlite3_column_text(stmt, 4) != nil ? String(cString: sqlite3_column_text(stmt, 4)) : ""
        let doctor = sqlite3_column_text(stmt, 5) != nil ? String(cString: sqlite3_column_text(stmt, 5)) : ""
        let stageStr = String(cString: sqlite3_column_text(stmt, 6))
        let priority = sqlite3_column_text(stmt, 7) != nil ? String(cString: sqlite3_column_text(stmt, 7)) : "Normal"
        let frame = sqlite3_column_text(stmt, 8) != nil ? String(cString: sqlite3_column_text(stmt, 8)) : ""
        let frameTypeStr = sqlite3_column_text(stmt, 9) != nil ? String(cString: sqlite3_column_text(stmt, 9)) : "PLASTIC_ZYL"
        let edger = sqlite3_column_text(stmt, 10) != nil ? String(cString: sqlite3_column_text(stmt, 10)) : ""
        
        let odSph = sqlite3_column_double(stmt, 11)
        let odCyl = sqlite3_column_double(stmt, 12)
        let odAxis = Int(sqlite3_column_int(stmt, 13))
        let odAdd = sqlite3_column_double(stmt, 14)
        let odPd = sqlite3_column_double(stmt, 15)
        let odSeg = sqlite3_column_double(stmt, 16)
        let odBarcode = sqlite3_column_text(stmt, 17) != nil ? String(cString: sqlite3_column_text(stmt, 17)) : ""
        
        let osSph = sqlite3_column_double(stmt, 18)
        let osCyl = sqlite3_column_double(stmt, 19)
        let osAxis = Int(sqlite3_column_int(stmt, 20))
        let osAdd = sqlite3_column_double(stmt, 21)
        let osPd = sqlite3_column_double(stmt, 22)
        let osSeg = sqlite3_column_double(stmt, 23)
        let osBarcode = sqlite3_column_text(stmt, 24) != nil ? String(cString: sqlite3_column_text(stmt, 24)) : ""
        
        let notes = sqlite3_column_text(stmt, 25) != nil ? String(cString: sqlite3_column_text(stmt, 25)) : ""
        let isArchived = sqlite3_column_int(stmt, 26) == 1
        let createdAt = Date(timeIntervalSince1970: Double(sqlite3_column_int64(stmt, 27)) / 1000.0)
        let updatedAt = Date(timeIntervalSince1970: Double(sqlite3_column_int64(stmt, 28)) / 1000.0)
        var completedAt: Date? = nil
        if sqlite3_column_type(stmt, 29) != SQLITE_NULL {
            completedAt = Date(timeIntervalSince1970: Double(sqlite3_column_int64(stmt, 29)) / 1000.0)
        }
        
        let stage = JobStage(rawValue: stageStr) ?? .newOrder
        let frameType = FrameType(rawValue: frameTypeStr) ?? .plasticZyl
        
        return OpticalJob(id: id, trayNumber: tray, orderNumber: order, patientName: patient, customerName: customer, doctorName: doctor, stage: stage, priority: priority, frameModel: frame, frameType: frameType, edgerMachine: edger, odSphere: odSph, odCylinder: odCyl, odAxis: odAxis, odAdd: odAdd, odPd: odPd, odSegHeight: odSeg, odLensBarcode: odBarcode, osSphere: osSph, osCylinder: osCyl, osAxis: osAxis, osAdd: osAdd, osPd: osPd, osSegHeight: osSeg, osLensBarcode: osBarcode, notes: notes, isArchived: isArchived, createdAt: createdAt, updatedAt: updatedAt, completedAt: completedAt)
    }
}
