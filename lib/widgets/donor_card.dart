import 'package:flutter/material.dart';
import '../models/donor_model.dart';
import '../theme/app_theme.dart';

class DonorCard extends StatelessWidget {
  final DonorModel donor;
  final bool isClosest;
  final VoidCallback? onContact;

  const DonorCard({super.key, required this.donor, this.isClosest = false, this.onContact});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isClosest ? AppTheme.green : AppTheme.gray100,
          width: isClosest ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            donor.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.gray900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isClosest) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded, color: AppTheme.green, size: 16),
                        ],
                      ],
                    ),
                    Text(
                      donor.type == 'hospital' ? 'Official Hospital' : 'Registered Donor',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray400),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.lightRed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    donor.bloodGroup,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryRed),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat(Icons.location_on_outlined, '${donor.distanceKm.toStringAsFixed(1)}km'),
              _stat(Icons.star_outline_rounded, '${donor.rating}'),
              _stat(Icons.volunteer_activism_outlined, '${donor.totalDonations}'),
              if (donor.type == 'hospital') _stat(Icons.inventory_2_outlined, '${donor.availableUnits ?? 0}'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: donor.isAvailable ? AppTheme.lightGreen : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: donor.isAvailable ? AppTheme.green : AppTheme.gray400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      donor.isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: donor.isAvailable ? AppTheme.green : AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onContact,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: donor.isAvailable ? AppTheme.primaryRed : AppTheme.gray200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: donor.isAvailable ? [
                      BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                    ] : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        donor.isAvailable ? Icons.phone_outlined : Icons.mail_outline_rounded,
                        color: donor.isAvailable ? Colors.white : AppTheme.gray600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        donor.isAvailable ? 'Contact' : 'Request',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: donor.isAvailable ? Colors.white : AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final colors = [AppTheme.lightGreen, AppTheme.lightBlue, AppTheme.lightOrange, AppTheme.lightRed];
    final textColors = [AppTheme.green, AppTheme.blue, AppTheme.orange, AppTheme.primaryRed];
    final idx = donor.id.hashCode.abs() % colors.length;
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: colors[idx],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          donor.initials,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColors[idx]),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gray400, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.gray700),
          ),
        ],
      ),
    );
  }
}
